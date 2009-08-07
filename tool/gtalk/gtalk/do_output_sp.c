#include <sp/spBaseLib.h>
#include <sp/spAudioLib.h>

#define GTALK_AUDIO_BLOCKSIZE 1024

void abort_auto_output();

static volatile spAudio gtalk_sp_audio = NULL;
static volatile int gtalk_aborted_flag = 0;

int in_auto_play;

/* nonzero value restarts play from beginning on replay */
static int gtalk_replay_init_flag = 0;

void output_speaker(int total) {}

void init_output() {}

void reset_audiodev() {}

void set_da_signal() {}

void abort_demanded_output() {
    if (gtalk_sp_audio != NULL) {
	long position;

	if (spGetAudioOutputPosition(gtalk_sp_audio, &position) == SP_TRUE) {
	    talked_DA_msec = (1000 * position) / SAMPLE_RATE;
	    spDebug(1, "abort_output", 
		    "spGetAudioOutputPosition: position = %ld, da_msec = %d, SAMPLE_RATE = %d\n", 
		    position, talked_DA_msec, SAMPLE_RATE);
	}

	if (!gtalk_aborted_flag) {
	    spDebug(1, "abort_output", "output aborted\n");
	    spStopAudio(gtalk_sp_audio);
	    gtalk_aborted_flag = 1;
	}

	if ( prop_Speak_len == AutoOutput )  inqSpeakLen();
	if ( prop_Speak_utt == AutoOutput )  inqSpeakUtt();
    }

}

static spThreadReturn do_output_thread(void *data)
{
    int total;
    int length;
    int offset;
    int block_length;

    spDebug(50, "do_output_thread", "in\n");

    total = *(int *)data;

    if (gtalk_sp_audio == NULL) {
	gtalk_sp_audio = spInitAudio();
	spSetAudioSampleRate(gtalk_sp_audio, (double)SAMPLE_RATE);
	spSetAudioBufferSize(gtalk_sp_audio, GTALK_AUDIO_BLOCKSIZE);
    }

    /* open "write only" mode */
    if (spOpenAudioDevice(gtalk_sp_audio, "wo") == SP_FALSE) {
	spDebug(1, "do_output_thread", "Can't open audio device\n");
	return SP_THREAD_RETURN_FAILURE;
    }

    offset = 0;
    block_length = GTALK_AUDIO_BLOCKSIZE * sizeof(short);

    while (!gtalk_aborted_flag && offset < total) {
	spDebug(80, "do_output_thread", "offset = %ld, total = %ld\n", offset, total);

	length = MIN(total - offset, block_length);
	spWriteAudio(gtalk_sp_audio, &wave.data[offset], length);

	offset += block_length;
    }

    if (!gtalk_aborted_flag) {
	long position;

	if (spGetAudioOutputPosition(gtalk_sp_audio, &position) == SP_TRUE) {
	    talked_DA_msec = (1000 * position) / SAMPLE_RATE;
	}
	if ( prop_Speak_len == AutoOutput )  inqSpeakLen();
	if ( prop_Speak_utt == AutoOutput )  inqSpeakUtt();
    }

    spCloseAudioDevice(gtalk_sp_audio);

    strcpy( slot_Speak_stat, "IDLE" );
    if( prop_Speak_stat == AutoOutput )  inqSpeakStat();

    spDebug(50, "do_output_thread", "done: offset = %d\n", offset);

    return SP_THREAD_RETURN_SUCCESS;
}

void do_output_info(char *);

void do_output_file_sp(char *sfile)
{
#if 1
    static char o_plugin_name[SP_MAX_LINE];
    spPlugin *o_plugin;
    spWaveInfo wave_info;

    spInitWaveInfo(&wave_info);
    wave_info.samp_rate = (double)SAMPLE_RATE;
    wave_info.num_channel = 1;

    strcpy(o_plugin_name, "");
    
    if ((o_plugin = spOpenFilePluginArg(o_plugin_name, sfile, "w",
					SP_PLUGIN_DEVICE_FILE,
					&wave_info, NULL, 0, NULL, NULL)) != NULL) {
	spWritePlugin(o_plugin, wave.data, wave.nsample);
	spCloseFilePlugin(o_plugin);
    } else {
	/*TmpMsg( "Cannot find suitable plugin for %s\n", sfile );*/
	do_output_file(sfile);
    }
    
    do_output_info(sfile);
#else
    do_output_file(sfile);
#endif
    
    return;
}

void do_output(char *fn)
{
    static int total;

	in_auto_play = 0;

    /*total = SAMPLE_RATE * FRAME_RATE * (totalframe - 1) / 1000;*/
    total = wave.nsample;
    if(fn == NULL){
	static void *thread = NULL;

	talked_DA_msec = -1;
	already_talked = 1;

	if (thread != NULL) {
	    if (gtalk_sp_audio != NULL && gtalk_replay_init_flag) {
		spStopAudio(gtalk_sp_audio);
	    }

	    spWaitThread(thread);
	    spDestroyThread(thread);
	}
	spDebug(1, "do_output", "creating thread...\n");

	gtalk_aborted_flag = 0;

	if ((thread = spCreateThread(0, SP_THREAD_PRIORITY_NORMAL, 
				     do_output_thread, (void *)&total)) == NULL) {
	    spDebug(1, "do_output", "Can't create audio thread\n");
	    return;
	}

	spDebug(1, "do_output", "creating thread done\n");
    } else {
#if 0
	FILE *fp;
	
	if ((fp = fopen(fn, "wb")) != NULL) {
	    fwrite(wave.data, sizeof (short), total, fp);
	    fclose(fp);
	}
#else
	do_output_file_sp( fn );
#endif
    }
}

void abort_output()
{
#ifdef AUTO_DA
	if( in_auto_play )  {
		abort_auto_output();
	} else {
		abort_demanded_output();
	}
#else
	abort_demanded_output();
#endif
}

/*--------------------------------------------------------------------
	AutoPlay
--------------------------------------------------------------------*/

#ifdef AUTO_DA

void do_auto_output()
{
    static int total;
	static void *thread = NULL;

	in_auto_play = 1;

    /*total = SAMPLE_RATE * FRAME_RATE * (totalframe - 1) / 1000;*/
    total = wave.nsample;

	talked_DA_msec = -1;
	already_talked = 1;

	if (thread != NULL) {
	    if (gtalk_sp_audio != NULL && gtalk_replay_init_flag) {
		spStopAudio(gtalk_sp_audio);
	    }

	    spWaitThread(thread);
	    spDestroyThread(thread);
	}
	spDebug(1, "do_output", "creating thread...\n");

	gtalk_aborted_flag = 0;

	if ((thread = spCreateThread(0, SP_THREAD_PRIORITY_NORMAL, 
				     do_output_thread, (void *)&total)) == NULL) {
	    spDebug(1, "do_output", "Can't create audio thread\n");
	    return;
	}

	spDebug(1, "do_output", "creating thread done\n");
}

void abort_auto_output() {
    if (gtalk_sp_audio != NULL) {
	long position;

	if (spGetAudioOutputPosition(gtalk_sp_audio, &position) == SP_TRUE) {
	    talked_DA_msec = (1000 * position) / SAMPLE_RATE;
	    spDebug(1, "abort_output", 
		    "spGetAudioOutputPosition: position = %ld, da_msec = %d, SAMPLE_RATE = %d\n", 
		    position, talked_DA_msec, SAMPLE_RATE);
	}

	if (!gtalk_aborted_flag) {
	    spDebug(1, "abort_output", "output aborted\n");
	    spStopAudio(gtalk_sp_audio);
	    gtalk_aborted_flag = 1;
	}

	if ( prop_Speak_len == AutoOutput )  inqSpeakLen();
	if ( prop_Speak_utt == AutoOutput )  inqSpeakUtt();
    }

}

#endif /* AUTO_DA */
