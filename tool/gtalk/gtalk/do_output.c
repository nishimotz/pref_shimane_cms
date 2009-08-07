/* Copyright (c) 2000-2003                             */
/*   Yoichi Yamashita                                  */
/*   Ritsumeikan University                            */
/*   Takuya Nishimoto                                  */
/*   Kyoto Insititute of Technology                    */
/*   Takao Kobayashi, Takashi Masuko, Masatsune Tamura */
/*   Tokyo Institute of Technology                     */
/*   Keiichi Tokuda, Takayoshi Yoshimura, Heiga Zen    */
/*   Nagoya Institute of Technology                    */
/*   All rights reserved                               */
/* Copyright (c) 2000-2003                             */
/*   Yoichi Yamashita                                  */
/*   Ritsumeikan University                            */
/*   Takuya Nishimoto                                  */
/*   Kyoto Insititute of Technology                    */
/*   Takao Kobayashi, Takashi Masuko, Masatsune Tamura */
/*   Tokyo Institute of Technology                     */
/*   Keiichi Tokuda, Takayoshi Yoshimura, Heiga Zen    */
/*   Nagoya Institute of Technology                    */
/*   All rights reserved                               */
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <unistd.h>
#include <signal.h>
#include <pthread.h>
#include <string.h>

#include "synthesis.h"
#include "defaults.h"
#include "confpara.h"
#include "misc.h"
#include "tree.h"
#include "hmmsynth.h"
#include "model.h"
#include "da.h"
#include "slot.h"

#define	SIZE	256*400
size_t		abuf_size;

int talked_DA_msec;
int already_talked;

#ifdef LINUX
int	org_vol, org_channels, org_precision, org_freq;
#endif /* LINUX */

#ifdef SOLARIS
audio_info_t	org_data;
#include <strings.h>
#endif /* SOLARIS */

int ErrMsg(char *,...);
int TmpMsg(char *,...);
void restart(int);
void inqSpeakLen();
void inqSpeakUtt();
void inqSpeakStat();

/*---------------------------------------------------------------------*/

#ifdef THREAD_DA
void set_da_signal() 
{
}

#else
static void sig_wait_da()
{
	int status;
	wait( &status );
	if( prop_Speak_len == AutoOutput )  inqSpeakLen();
	if( prop_Speak_utt == AutoOutput )  inqSpeakUtt();
	strcpy( slot_Speak_stat, "IDLE" );
	if( prop_Speak_stat == AutoOutput )  inqSpeakStat();
}

void set_da_signal()
{
	signal( SIGCHLD, sig_wait_da );
}
#endif

/*---------------------------------------------------------------------*/

void reset_output()
{
	void reset_audiodev();
	fclose( adfp);
	close( ACFD);

	reset_audiodev();
}

void init_output()
{
	int	dtype;
	void	init_audiodev();

	dtype = DTYPE;
	init_audiodev(dtype);
}

void sndout(leng, out)
int	leng;
short	*out;
{
	fwrite( out, sizeof(short), leng, adfp);
	write( ADFD, out, 0);
}

void init_audiodev(dtype)
int	dtype;
{
#ifdef LINUX
	int arg;
	if( (adfp = fopen( AUDIO_DEV, "w")) == NULL){
		ErrMsg("can't open audio device\n");
		restart( 1 );
	}
	ADFD = adfp->_fileno;
	ACFD = open( MIXER_DEV, O_RDWR, 0);

	ioctl(ADFD, SNDCTL_DSP_GETBLKSIZE, &abuf_size);
	ioctl(ADFD, SOUND_PCM_READ_BITS, &org_precision);
	ioctl(ADFD, SOUND_PCM_READ_CHANNELS, &org_channels);
	ioctl(ADFD, SOUND_PCM_READ_RATE, &org_freq);
	ioctl(ACFD, SOUND_MIXER_READ_PCM, &org_vol);
	
	arg = data_type[dtype].precision;
	ioctl(ADFD, SOUND_PCM_WRITE_BITS, &arg);
/*	arg = data_type[dtype].channel; */
	arg = 0;
	ioctl(ADFD, SOUND_PCM_WRITE_CHANNELS, &arg);
	arg = data_type[dtype].sample;
	ioctl(ADFD, SOUND_PCM_WRITE_RATE, &arg);
#endif /* LINUX */
#ifdef SOLARIS
	audio_info_t	data;

	ACFD = open(AUDIO_CTLDEV, O_RDWR, 0);
	if( (adfp = fopen(AUDIO_DEV, "w")) == NULL){
	    ErrMsg( "can't open audio device\n");
	    restart(1);
	}
	ADFD = adfp->_file;

	AUDIO_INITINFO(&data);
	ioctl(ACFD, AUDIO_GETINFO, &data);
	bcopy( &data, &org_data, sizeof( audio_info_t));

	data.play.sample_rate = data_type[dtype].sample;
	data.play.precision   = data_type[dtype].precision;
	data.play.encoding    = data_type[dtype].encoding;

	ioctl(ADFD,AUDIO_SETINFO,&data);
#endif /* SOLARIS */
}

void reset_audiodev()
{
#ifdef LINUX
	ACFD = open( MIXER_DEV, O_RDWR, 0);
	/*	ADFD = open( AUDIO_DEV, O_RDWR, 0); */
	ADFD = open( AUDIO_DEV, O_WRONLY, 0);

	ioctl(ADFD, SOUND_PCM_WRITE_BITS, &org_precision);
	ioctl(ADFD, SOUND_PCM_WRITE_CHANNELS, &org_channels);
	ioctl(ADFD, SOUND_PCM_WRITE_RATE, &org_freq);
	ioctl(ACFD, SOUND_MIXER_WRITE_PCM, &org_vol);

	close( ADFD);
	close( ACFD);
#endif /* linux */
#ifdef SOLARIS
	ACFD = open(AUDIO_CTLDEV, O_RDWR, 0);
	ioctl( ACFD, AUDIO_SETINFO, &org_data);
	close( ACFD);
#endif /* SOLARIS */
}

/*---------------------------------------------------------------------*/
#if defined(LINUX) || defined(SOLARIS)

struct timeval tv;
struct timezone tz;
static int start_DA_sec;
static int start_DA_usec;

#ifdef THREAD_DA

pthread_t thread;

void output_speaker_cleanup(void *dummy)
{

  reset_output();
  strcpy( slot_Speak_stat, "IDLE" );
  if( prop_Speak_stat == AutoOutput )  inqSpeakStat();

}

void output_speaker_thread(int *t)
{

  int total = *t;
  int nout;
  int last_state, last_type;

  pthread_setcanceltype(PTHREAD_CANCEL_DEFERRED, &last_type);
  pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, &last_state);
  pthread_cleanup_push((void *)output_speaker_cleanup, NULL);
  
  init_output();
  nout = 0;
  while ( nout < total - SIZE)  {
    sndout(SIZE,&wave.data[nout]);
    nout += SIZE;
    pthread_testcancel();
  }
  sndout(total - nout, &wave.data[nout]);
  ioctl(ADFD, SOUND_PCM_SYNC, 0);

  pthread_cleanup_pop(1);
  return;

}

void abort_output()
{
  void *statusp;

  gettimeofday( &tv, &tz );
/*
  printf( "tv: %d %d\n", tv.tv_sec, tv.tv_usec );
*/
  talked_DA_msec = (tv.tv_sec-start_DA_sec)*1000 + 
                   (tv.tv_usec-start_DA_usec)/1000.;

  pthread_cancel(thread);
  pthread_join(thread, &statusp);

  if( prop_Speak_len == AutoOutput )  inqSpeakLen();
  if( prop_Speak_utt == AutoOutput )  inqSpeakUtt();
}

#else /* Not THREAD_DA */

static int da_process = -1;

void output_speaker( int total )
{
	int nout;

	if( (da_process=fork())==0 )  {
		setpgrp();
		init_output();
		nout = 0;
		while ( nout < total - SIZE)  {
			sndout(SIZE,&wave.data[nout]);
			nout += SIZE;
		}
		sndout(total - nout, &wave.data[nout]);
#ifdef LINUX
		ioctl(ADFD, SOUND_PCM_SYNC, 0);
#endif /* LINUX */
		reset_output();
		exit(0);
	} else {
//		wait( &status );	
	}
}

void abort_output()
{
	gettimeofday( &tv, &tz );
	talked_DA_msec = (tv.tv_sec-start_DA_sec)*1000 + 
	                 (tv.tv_usec-start_DA_usec)/1000.;

/* da_process を一度も作らないで kill すると abort する。*/
	if( da_process >= 0 )  {
		kill( da_process, SIGKILL );
		TmpMsg( "DA process was killed\n" );
	}
}

#endif /* THREAD_DA */

#else

void abort_output(){}

#endif /* LINUX || SOLARIS */



/*---------------------------------------------------------------------*/

void do_output(char *fn)
{
    FILE *fp;
    /*    int total; */
    static int total;

    total = SAMPLE_RATE * FRAME_RATE * (totalframe - 1) / 1000;
    if(fn == NULL){
#if defined(LINUX) || defined(SOLARIS)
	gettimeofday( &tv, &tz );
/*	printf( "tv: %d %d\n", (int)tv.tv_sec, (int)tv.tv_usec );	*/
	start_DA_sec = (int)tv.tv_sec;
	start_DA_usec = (int)tv.tv_usec;
	talked_DA_msec = -1;
	already_talked = 1;

#ifdef THREAD_DA
	pthread_create(&thread,
	     NULL,
	     (void *) output_speaker_thread,
	     (void *) &total);
#else
		output_speaker( total );
#endif /* THREAD_DA */
#else
		TmpMsg( "Sorry. Not implemented ...\n" );
#endif /* LINUX || SOLARIS */
    } else {
      fp = fopen(fn,"w");
      fwrite(wave.data, sizeof (short), total, fp);
      fclose(fp);
    }
}
