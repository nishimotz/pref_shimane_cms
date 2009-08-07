<?xml version="1.0" encoding="Shift_JIS"?>

<!-- XSLT stylesheet for ChaOne              -->
<!--                     for msxml and exslt -->
<!--                            ver. 1.2.0b4 -->
<!--  (1) ChaSen Chunker                     -->
<!--                2005-03-25 by Studio ARC -->
<!-- Copyright (c) 2004-2005 Studio ARC      -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:msxml="urn:schemas-microsoft-com:xslt"
  xmlns:ext="http://exslt.org/common"
  exclude-result-prefixes="exsl msxml ext"
  version="1.0"
  xml:lang="ja">

  <xsl:output method="xml" encoding="Shift_JIS" omit-xml-declaration="yes" indent="yes"/>

  <xsl:variable name="chunk_rules" select="document('chunk_rules.xml')/chunk_rules"/>

  <xsl:template match="/">
    <xsl:apply-templates select="S"/>
  </xsl:template>

  <xsl:template match="S">
    <xsl:copy>
      <xsl:apply-templates mode="chunker"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*[not(self::W1)]" priority="-10" mode="chunker">
    <!-- W1�ȊO�̏��� -->
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="child::*" mode="chunker"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="W1[(position() = 1)
                          or (preceding-sibling::W1[1][@w2Chunk = 'E'])
                          or (preceding-sibling::*[1][not(self::W1)])]" mode="chunker">
    <!-- �擪�Ȃ���E�̌��Ȃ���W1�ȊO�̃m�[�h�̌��̃m�[�h��I�� -->
    <!-- �擪�Ȃ���E�̌��Ȃ���W1�ȊO�̃m�[�h�̌�납��A�Ō�Ȃ���B�Ȃ���W1�ȊO�̑O�܂ł̃m�[�h���Ώ� -->
    <xsl:call-template name="select-target"/>
  </xsl:template>

  <xsl:template name="select-target">
    <!-- �K���K�p�͈͂̌���ƓK�p -->
    <!-- current = "W1" -->
    <xsl:variable name="from">
      <xsl:apply-templates select="." mode="get-position"/>
    </xsl:variable>
    <xsl:variable name="to">
      <xsl:call-template name="calc-to">
        <xsl:with-param name="from" select="$from"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="selected-rules">
      <xsl:call-template name="select-rules">
        <xsl:with-param name="input" select="parent::*[1]"/>
        <xsl:with-param name="from" select="$from"/>
        <xsl:with-param name="to" select="$to"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="apply-rules">
      <xsl:with-param name="input" select="parent::*[1]"/>
      <xsl:with-param name="from" select="$from"/>
      <xsl:with-param name="to" select="$to"/>
      <xsl:with-param name="rules">
        <xsl:for-each select="ext:node-set($selected-rules)/range">
          <xsl:sort select="@from" data-type="number"/>
          <xsl:copy-of select="."/>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="calc-to">
    <!-- �Ō�Ȃ���B�̑O�Ȃ���W1�ȊO�̃m�[�h�̑O�̃m�[�h�̂����ł��O�̈ʒu��Ԃ� -->
    <xsl:param name="from"/>
    <xsl:variable name="Bpos">
      <xsl:if test="following-sibling::W1[@w2Chunk = 'B']">
        <xsl:choose>
          <xsl:when test="following-sibling::W1[1][@w2Chunk = 'B']">
            <xsl:value-of select="$from"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates
              select="following-sibling::W1[not(@w2Chunk)][following-sibling::W1[1][@w2Chunk = 'B']][1]"
              mode="get-position"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="nonW1pos">
      <xsl:if test="following-sibling::*[not(self::W1)]">
        <xsl:variable name="nonW1poscand">
          <xsl:choose>
            <xsl:when test="following-sibling::*[1][not(self::W1)]">
              <xsl:value-of select="$from"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates
                select="following-sibling::W1[following-sibling::*[1][not(self::W1)]][1]"
                mode="get-position"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="number($nonW1poscand)">
            <xsl:value-of select="$nonW1poscand"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$from"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="lastpos">
      <xsl:apply-templates
        select="following-sibling::W1[last()]"
        mode="get-position"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="number($Bpos) and number($nonW1pos)">
        <xsl:choose>
          <xsl:when test="number($nonW1pos) > number($Bpos)">
            <xsl:value-of select="$Bpos"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$nonW1pos"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="number($Bpos)">
        <xsl:value-of select="$Bpos"/>
      </xsl:when>
      <xsl:when test="number($nonW1pos)">
        <xsl:value-of select="$nonW1pos"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="number($lastpos)">
            <xsl:value-of select="$lastpos"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$from"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="node()" mode="get-position">
    <xsl:value-of select="count(preceding-sibling::*) + 1"/>
  </xsl:template>

  <xsl:template name="select-rules">
    <!-- current = "W1" -->
    <!-- returns <range rule="id" from="from" to="to"/>... -->
    <xsl:param name="input"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <!-- �K�p�\�Ȃ��ׂĂ̋K���ɂ���'id,from,to'���v�Z���� -->
    <xsl:variable name="applicable-rules">
      <xsl:for-each select="$chunk_rules/rule">
        <xsl:call-template name="check-rule">
          <xsl:with-param name="input" select="$input"/>
          <xsl:with-param name="from" select="$from"/>
          <xsl:with-param name="to" select="$to"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>
    <!-- ���̂����K�p�͈͂̍L�����̂��珇�ɗ����\�Ȃ��� -->
    <xsl:variable name="sorted-rules">
      <xsl:for-each select="ext:node-set($applicable-rules)/range">
        <xsl:sort select="@to - @from" order="descending" data-type="number"/>
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:apply-templates select="ext:node-set($sorted-rules)/range" mode="chk"/>
  </xsl:template>

  <xsl:template match="range" mode="chk">
    <xsl:variable name="rfrom" select="@from"/>
    <xsl:variable name="rto" select="@to"/>
    <xsl:variable name="chk">
      <xsl:for-each select="preceding-sibling::range">
        <xsl:choose>
          <xsl:when test="(number($rto) &lt; number(@from)) or (number($rfrom) > number(@to))">
            <xsl:text>T</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>F</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="not(contains($chk, 'F'))">
      <xsl:copy-of select="."/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="check-rule">
    <!-- �����rule��$from����$to�͈̔͂̂ǂ����ɓK�p�\���ǂ����̃`�F�b�N -->
    <!-- ���Yrule��rhs�����ׂĖ�������邩�ǂ��� -->
    <!-- current = "rule" -->
    <!-- returns <range id="id" from="from" to="to"/>... -->
    <xsl:param name="input"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:variable name="results">
      <xsl:call-template name="check-rule-top">
        <xsl:with-param name="input" select="$input"/>
        <xsl:with-param name="from" select="$from"/>
        <xsl:with-param name="to" select="$to"/>
      </xsl:call-template>
    </xsl:variable>
    <!-- return value -->
    <xsl:variable name="id" select="@id"/>
    <xsl:apply-templates select="ext:node-set($results)/range" mode="result">
      <xsl:with-param name="id" select="$id"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="range" mode="result">
    <xsl:param name="id"/>
    <xsl:copy>
      <xsl:attribute name="id">
        <xsl:value-of select="$id"/>
      </xsl:attribute>
      <xsl:copy-of select="@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="check-rule-top">
    <!-- returns <range from="from" to="to"/> ... -->
    <!-- current = "rule" -->
    <xsl:param name="input"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:variable name="targets"
                  select="$input/*[(position() >= number($from)) and (position() &lt;= number($to))]"/>

    <xsl:choose>
      <!-- rhs�̃g�b�v�ɂ�W1�Ȃ���choice������Ɖ��� -->
      <xsl:when test="rhs/W1">
        <!-- rhs�̃g�b�v�̐擪��W1�ɂ��ď��� -->
        <xsl:variable name="rhs-cur" select="rhs/W1[1]"/>
        <xsl:variable name="rhs-pre" select="rhs/*[generate-id(following-sibling::W1[1]) = generate-id($rhs-cur)]"/>
        <xsl:variable name="rhs-post" select="rhs/*[generate-id(preceding-sibling::W1[last()]) = generate-id($rhs-cur)]"/>
        <xsl:choose>
          <xsl:when test="$targets[self::W1 and contains(@pos, $rhs-cur/@pos)]">
            <xsl:variable name="hit-locs">
              <xsl:for-each select="$targets[self::W1 and contains(@pos, $rhs-cur/@pos)]">
                <hit>
                  <xsl:apply-templates select="." mode="get-position"/>
                </hit>
                </xsl:for-each>
            </xsl:variable>
            <!-- $targets�̂��������𖞂������ׂĂ�W1�ɂ��ď��� -->
            <xsl:variable name="results">
              <xsl:for-each select="ext:node-set($hit-locs)/hit">
                <xsl:call-template name="calc-result">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="hit-loc" select="."/>
                  <xsl:with-param name="rhs-pre" select="$rhs-pre"/>
                  <xsl:with-param name="rhs-post" select="$rhs-post"/>
                  <xsl:with-param name="from" select="$from"/>
                  <xsl:with-param name="to" select="$to"/>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:variable>
            <xsl:copy-of select="$results"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>F</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="rhs/choice">
      <!-- *** -->
      </xsl:when>
      <!--
      <xsl:when test="rhs/zeroOrMore">
      </xsl:when>
      <xsl:when test="rhs/oneOrMore">
      </xsl:when>
      <xsl:when test="rhs/optional">
      </xsl:when>
      -->
    </xsl:choose>
  </xsl:template>

  <xsl:template name="calc-result">
    <!-- current = "rule" -->
    <!-- returns <range from="from" to="to"/> or 'F' -->
    <xsl:param name="input"/>
    <xsl:param name="hit-loc"/>
    <xsl:param name="rhs-pre"/>
    <xsl:param name="rhs-post"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:variable name="rhs-pre-result">
      <xsl:if test="count($rhs-pre)">
        <xsl:call-template name="check-rule-pre">
          <xsl:with-param name="input" select="$input"/>
          <xsl:with-param name="from" select="$from"/>
          <xsl:with-param name="to" select="$hit-loc - 1"/>
          <xsl:with-param name="rhs" select="$rhs-pre"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="rhs-post-result">
      <xsl:if test="count($rhs-post)">
        <xsl:call-template name="check-rule-post">
          <xsl:with-param name="input" select="$input"/>
          <xsl:with-param name="from" select="$hit-loc + 1"/>
          <xsl:with-param name="to" select="$to"/>
          <xsl:with-param name="rhs" select="$rhs-post"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="($rhs-pre-result = 'F') or ($rhs-post-result = 'F')">
        <xsl:text>F</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="range">
          <xsl:attribute name="from">
            <xsl:choose>
              <xsl:when test="$rhs-pre-result != ''">
                <xsl:value-of select="$rhs-pre-result"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$hit-loc"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="to">
            <xsl:choose>
              <xsl:when test="$rhs-post-result != ''">
                <xsl:value-of select="$rhs-post-result"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$hit-loc"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="check-rule-pre">
    <!-- returns 'from' or 'F' -->
    <!-- current = "text()" -->
    <xsl:param name="input"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:param name="rhs"/>
    <xsl:call-template name="check-rule-des">
      <xsl:with-param name="input" select="$input"/>
      <xsl:with-param name="dir" select="'pre'"/>
      <xsl:with-param name="from" select="$from"/>
      <xsl:with-param name="to" select="$to"/>
      <xsl:with-param name="rhs" select="$rhs"/>
      <xsl:with-param name="rhs-cur" select="$rhs[last()]"/>
      <xsl:with-param name="rhs-des" select="$rhs[position() != last()]"/>
      <xsl:with-param name="target-cur" select="$input/*[number($to)]"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="check-rule-post">
    <!-- returns 'to' or 'F' -->
    <!-- current = "text()" -->
    <xsl:param name="input"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:param name="rhs"/>
    <xsl:call-template name="check-rule-des">
      <xsl:with-param name="input" select="$input"/>
      <xsl:with-param name="dir" select="'post'"/>
      <xsl:with-param name="from" select="$from"/>
      <xsl:with-param name="to" select="$to"/>
      <xsl:with-param name="rhs" select="$rhs"/>
      <xsl:with-param name="rhs-cur" select="$rhs[1]"/>
      <xsl:with-param name="rhs-des" select="$rhs[position() != 1]"/>
      <xsl:with-param name="target-cur" select="$input/*[number($from)]"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="check-rule-des">
    <!-- returns 'from | to' or 'F' -->
    <!-- current = "text()" -->
    <xsl:param name="input"/>
    <xsl:param name="dir"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:param name="rhs"/>
    <xsl:param name="rhs-cur"/>
    <xsl:param name="rhs-des"/>
    <xsl:param name="target-cur"/>
    <xsl:variable name="targets" select="$input/*[(position() >= number($from)) and (position() &lt;= number($to))]"/>
    <xsl:variable name="end">
      <xsl:choose>
        <xsl:when test="$dir = 'pre'">
          <xsl:value-of select="$from"/>
        </xsl:when>
        <xsl:when test="$dir = 'post'">
          <xsl:value-of select="$to"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$rhs-cur[name() = 'W1']">
        <xsl:choose>
          <xsl:when test="$target-cur[starts-with(@pos, $rhs-cur/@pos)]">
            <xsl:call-template name="check-rule-des-next-one">
              <xsl:with-param name="input" select="$input"/>
              <xsl:with-param name="dir" select="$dir"/>
              <xsl:with-param name="end" select="$end"/>
              <xsl:with-param name="rhs-des" select="$rhs-des"/>
              <xsl:with-param name="target-cur" select="$target-cur"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>F</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$rhs-cur[name() = 'zeroOrMore']">
      <!-- �q�Ƃ���W1�Ȃ���choice����������� -->
        <xsl:choose>
          <xsl:when test="$rhs-cur/W1">
            <xsl:choose>
              <xsl:when test="$target-cur[starts-with(@pos, $rhs-cur/W1/@pos)]">
                <!-- $targets �̂����A�Ō�����猩�ď����𖞂������т̐擪 -->
                <xsl:call-template name="check-rule-des-next-more">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="rhs-cur" select="$rhs-cur"/>
                  <xsl:with-param name="targets" select="$targets"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <!-- next processing -->
                <xsl:call-template name="check-rule-des-next-zero">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="from" select="$from"/>
                  <xsl:with-param name="to" select="$to"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$rhs-cur/choice">
            <!-- select candidate that matches target-cur -->
            <xsl:variable name="choice-res">
              <xsl:for-each select="$rhs-cur/choice/W1">
                <xsl:if test="$target-cur[starts-with(@pos, ./@pos)]">
                  <xsl:text>T</xsl:text>
                </xsl:if>
              </xsl:for-each>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="contains($choice-res, 'T')">
                <xsl:call-template name="check-rule-des-next-more">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="rhs-cur" select="$rhs-cur"/>
                  <xsl:with-param name="targets" select="$targets"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <!-- next processing -->
                <xsl:call-template name="check-rule-des-next-zero">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="from" select="$from"/>
                  <xsl:with-param name="to" select="$to"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <!--
      <xsl:when test="$rhs-cur[name() = 'oneOrMore']">
      </xsl:when>
      -->
      <xsl:when test="$rhs-cur[name() = 'optional']">
        <!-- �q�Ƃ���W1�Ȃ���choice����������� -->
        <xsl:choose>
          <xsl:when test="$rhs-cur/W1">
            <xsl:choose>
              <xsl:when test="$target-cur[starts-with(@pos, $rhs-cur/W1/@pos)]">
                <xsl:call-template name="check-rule-des-next-one">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="target-cur" select="$target-cur"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <!-- next processing -->
                <xsl:call-template name="check-rule-des-next-zero">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="from" select="$from"/>
                  <xsl:with-param name="to" select="$to"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$rhs-cur/choice">
            <!-- select candidate that matches target-cur -->
            <xsl:variable name="choice-res">
              <xsl:for-each select="$rhs-cur/choice/W1">
                <xsl:if test="$target-cur[starts-with(@pos, ./@pos)]">
                  <xsl:text>T</xsl:text>
                </xsl:if>
              </xsl:for-each>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="contains($choice-res, 'T')">
                <xsl:call-template name="check-rule-des-next-one">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="target-cur" select="$target-cur"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <!-- next processing -->
                <xsl:call-template name="check-rule-des-next-zero">
                  <xsl:with-param name="input" select="$input"/>
                  <xsl:with-param name="dir" select="$dir"/>
                  <xsl:with-param name="end" select="$end"/>
                  <xsl:with-param name="rhs-des" select="$rhs-des"/>
                  <xsl:with-param name="from" select="$from"/>
                  <xsl:with-param name="to" select="$to"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$rhs-cur[name() = 'choice']">
        <!-- select candidate that matches target-cur -->
        <xsl:variable name="choice-res">
          <xsl:for-each select="$rhs-cur/W1">
            <xsl:if test="$target-cur[starts-with(@pos, ./@pos)]">
              <xsl:text>T</xsl:text>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="contains($choice-res, 'T')">
            <xsl:call-template name="check-rule-des-next-one">
              <xsl:with-param name="input" select="$input"/>
              <xsl:with-param name="dir" select="$dir"/>
              <xsl:with-param name="end" select="$end"/>
              <xsl:with-param name="rhs-des" select="$rhs-des"/>
              <xsl:with-param name="target-cur" select="$target-cur"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>F</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="des-bound">
    <xsl:param name="dir"/>
    <xsl:param name="rhs-cur"/>
    <xsl:param name="targets"/>
    <xsl:choose>
      <xsl:when test="$dir = 'pre'">
        <xsl:choose>
          <xsl:when test="$rhs-cur/W1">
            <xsl:variable name="nomatch" select="$targets[not(starts-with(@pos, $rhs-cur/W1/@pos))]"/>
            <xsl:choose>
              <xsl:when test="count($nomatch)">
                <xsl:variable name="nmlp">
                  <xsl:apply-templates select="$nomatch[last()]" mode="get-position"/>
                </xsl:variable>
                <xsl:value-of select="$nmlp + 1"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="$targets[1]" mode="get-position"/>
              </xsl:otherwise>
            </xsl:choose>      
          </xsl:when>
          <xsl:when test="$rhs-cur/choice">
            <xsl:variable name="nmlocs">
              <xsl:for-each select="$targets">
                <xsl:variable name="ct" select="."/>
                <xsl:variable name="chit">
                  <xsl:for-each select="$rhs-cur/choice/W1">
                    <xsl:if test="starts-with($ct/@pos, @pos)">
                      <xsl:text>T</xsl:text>
                    </xsl:if>
                  </xsl:for-each>
                </xsl:variable>
                <xsl:if test="not(contains($chit, 'T'))">
                  <xsl:text>#</xsl:text>
                  <xsl:value-of select="position()"/>
                  <xsl:text>#</xsl:text>
                </xsl:if>
              </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="nomatch" select="$targets[contains($nmlocs, concat('#', position(), '#'))]"/>
            <xsl:choose>
              <xsl:when test="count($nomatch)">
                <xsl:variable name="nmlp">
                  <xsl:apply-templates select="$nomatch[last()]" mode="get-position"/>
                </xsl:variable>
                <xsl:value-of select="$nmlp + 1"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="$targets[1]" mode="get-position"/>
              </xsl:otherwise>
            </xsl:choose>      
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$dir = 'post'">
        <xsl:choose>
          <xsl:when test="$rhs-cur/W1">
            <xsl:variable name="nomatch" select="$targets[not(starts-with(@pos, $rhs-cur/W1/@pos))]"/>
            <xsl:choose>
              <xsl:when test="count($nomatch)">
                <xsl:variable name="nmfp">
                  <xsl:apply-templates select="$nomatch[1]" mode="get-position"/>
                </xsl:variable>
                <xsl:value-of select="$nmfp - 1"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="$targets[last()]" mode="get-position"/>
              </xsl:otherwise>
            </xsl:choose>      
          </xsl:when>
          <xsl:when test="$rhs-cur/choice">
            <xsl:variable name="nmlocs">
              <xsl:for-each select="$targets">
                <xsl:variable name="ct" select="."/>
                <xsl:variable name="chit">
                  <xsl:for-each select="$rhs-cur/choice/W1">
                    <xsl:if test="starts-with($ct/@pos, @pos)">
                      <xsl:text>T</xsl:text>
                    </xsl:if>
                  </xsl:for-each>
                </xsl:variable>
                <xsl:if test="not(contains($chit, 'T'))">
                  <xsl:text>#</xsl:text>
                  <xsl:value-of select="position()"/>
                  <xsl:text>#</xsl:text>
                </xsl:if>
              </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="nomatch" select="$targets[contains($nmlocs, concat('#', position(), '#'))]"/>
            <xsl:choose>
              <xsl:when test="count($nomatch)">
                <xsl:variable name="nmfp">
                  <xsl:apply-templates select="$nomatch[1]" mode="get-position"/>
                </xsl:variable>
                <xsl:value-of select="$nmfp - 1"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="$targets[last()]" mode="get-position"/>
              </xsl:otherwise>
            </xsl:choose>      
          </xsl:when>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="check-rule-des-next-one">
    <xsl:param name="input"/>
    <xsl:param name="dir"/>
    <xsl:param name="end"/>
    <xsl:param name="rhs-des"/>
    <xsl:param name="target-cur"/>
    <xsl:call-template name="check-rule-des-next-main">
      <xsl:with-param name="input" select="$input"/>
      <xsl:with-param name="dir" select="$dir"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="rhs-des" select="$rhs-des"/>
      <xsl:with-param name="hit-loc">
        <xsl:apply-templates select="$target-cur" mode="get-position"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="check-rule-des-next-more">
    <xsl:param name="input"/>
    <xsl:param name="dir"/>
    <xsl:param name="end"/>
    <xsl:param name="rhs-des"/>
    <xsl:param name="rhs-cur"/>
    <xsl:param name="targets"/>
    <xsl:call-template name="check-rule-des-next-main">
      <xsl:with-param name="input" select="$input"/>
      <xsl:with-param name="dir" select="$dir"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="rhs-des" select="$rhs-des"/>
      <xsl:with-param name="hit-loc">
        <xsl:call-template name="des-bound">
          <xsl:with-param name="dir" select="$dir"/>
          <xsl:with-param name="rhs-cur" select="$rhs-cur"/>
          <xsl:with-param name="targets" select="$targets"/>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="check-rule-des-next-zero">
    <xsl:param name="input"/>
    <xsl:param name="dir"/>
    <xsl:param name="end"/>
    <xsl:param name="rhs-des"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:call-template name="check-rule-des-next-main">
      <xsl:with-param name="input" select="$input"/>
      <xsl:with-param name="dir" select="$dir"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="rhs-des" select="$rhs-des"/>
      <xsl:with-param name="hit-loc">
        <xsl:choose>
          <xsl:when test="$dir = 'pre'">
            <xsl:value-of select="$to + 1"/>
          </xsl:when>
          <xsl:when test="$dir = 'post'">
            <xsl:value-of select="$from - 1"/>
          </xsl:when>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="check-rule-des-next-main">
    <!-- current = "text()" -->
    <xsl:param name="input"/>
    <xsl:param name="dir"/>
    <xsl:param name="end"/>
    <xsl:param name="rhs-des"/>
    <xsl:param name="hit-loc"/>
    <xsl:variable name="rhs-des-result">
      <xsl:if test="count($rhs-des)">
       	<xsl:choose>
          <xsl:when test="$dir = 'pre'">
            <!-- *** recursive call *** -->
            <xsl:call-template name="check-rule-des">
              <xsl:with-param name="input" select="$input"/>
              <xsl:with-param name="dir" select="$dir"/>
              <xsl:with-param name="from" select="$end"/>
              <xsl:with-param name="to" select="$hit-loc - 1"/>
              <xsl:with-param name="rhs" select="$rhs-des"/>
              <xsl:with-param name="rhs-cur" select="$rhs-des[last()]"/>
              <xsl:with-param name="rhs-des" select="$rhs-des[position() != last()]"/>
              <xsl:with-param name="target-cur" select="$input/*[number($hit-loc) - 1]"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="$dir = 'post'">
            <!-- *** recursive call *** -->
            <xsl:call-template name="check-rule-des">
              <xsl:with-param name="input" select="$input"/>
              <xsl:with-param name="dir" select="$dir"/>
              <xsl:with-param name="from" select="$hit-loc + 1"/>
              <xsl:with-param name="to" select="$end"/>
              <xsl:with-param name="rhs" select="$rhs-des"/>
              <xsl:with-param name="rhs-cur" select="$rhs-des[1]"/>
              <xsl:with-param name="rhs-des" select="$rhs-des[position() != 1]"/>
              <xsl:with-param name="target-cur" select="$input/*[number($hit-loc) + 1]"/>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$rhs-des-result = 'F'">
        <xsl:text>F</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$rhs-des-result != ''">
            <xsl:value-of select="$rhs-des-result"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$hit-loc"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- ���������K���Ƀ}�b�`����W1�m�[�h�Z�b�g�����W2�̍쐬 -->

  <xsl:template name="apply-rules">
    <xsl:param name="input"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:param name="rules"/>
    <xsl:apply-templates select="ext:node-set($rules)/range" mode="apply">
      <xsl:with-param name="input" select="$input"/>
      <xsl:with-param name="from" select="$from"/>
      <xsl:with-param name="to" select="$to"/>
      <xsl:with-param name="rules" select="$rules"/>
    </xsl:apply-templates>
    <xsl:variable name="lastto" select="ext:node-set($rules)/range[last()]/@to"/>
    <xsl:variable name="last">
      <xsl:choose>
        <xsl:when test="$lastto >= 0">
          <xsl:value-of select="number($lastto) + 1"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$from"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="number($to) >= number($last)">
      <xsl:for-each select="$input/*[(position() >= number($last)) and (position() &lt;= number($to))]">
        <xsl:call-template name="wrapW1">
          <xsl:with-param name="target" select="."/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template name="wrapW1">
    <xsl:param name="target"/>
    <xsl:choose>
      <xsl:when test="$target[name() = 'W1']">
        <W2>
          <xsl:copy-of select="@*[(name() = 'orth') or (name() = 'pron') or (name() = 'pos')]"/>
          <xsl:copy-of select="$target"/>
        </W2>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$target"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="range" mode="apply">
    <xsl:param name="input"/>
    <xsl:param name="from"/>
    <xsl:param name="to"/>
    <xsl:param name="rules"/>
    <xsl:variable name="last">
      <xsl:choose>
        <xsl:when test="position() = 1">
          <xsl:value-of select="$from"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="number(preceding-sibling::range[1]/@to) + 1"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="rid" select="@id"/>
    <xsl:variable name="rfrom" select="@from"/>
    <xsl:variable name="rto" select="@to"/>
    <xsl:if test="number($last) &lt; number(@from)">
      <xsl:for-each select="$input/*[(position() >= number($last)) and (position() &lt; number($rfrom))]">
        <xsl:call-template name="wrapW1">
          <xsl:with-param name="target" select="."/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>
    <W2>
      <xsl:attribute name="orth">
        <xsl:for-each select="$input/*[(position() >= number($rfrom)) and (position() &lt;= number($rto))]">
          <xsl:value-of select="@orth"/>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:attribute name="pos">
       <xsl:value-of select="$chunk_rules/rule[@id = $rid]/lhs/W2/@pos"/>
      </xsl:attribute>
      <xsl:variable name="cType" select="$input/*[number($rto)]/@cType"/>
      <xsl:if test="$cType">
        <xsl:attribute name="cType">
          <xsl:value-of select="$cType"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:variable name="cForm" select="$input/*[number($rto)]/@cForm"/>
      <xsl:if test="$cForm">
        <xsl:attribute name="cForm">
          <xsl:value-of select="$cForm"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:for-each select="$input/*[(position() >= number($rfrom)) and (position() &lt;= number($rto))]">
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </W2>
  </xsl:template>

<!-- B,I,E�ɂ��W2�̍쐬 -->

  <xsl:template match="W1[@w2Chunk = 'B']" priority="10" mode="chunker">
    <xsl:variable name="nthB" select="count(preceding-sibling::W1[@w2Chunk = 'B']) + 1"/>
    <xsl:element name="W2">
      <xsl:for-each select="@*[starts-with(name(), 'w2_')]">
        <xsl:attribute name="{substring-after(name(), 'w2_')}">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:for-each>
      <xsl:apply-templates select="." mode="delete-w2-info"/>
      <xsl:apply-templates select="following-sibling::W1[(@w2Chunk = 'I') and (count(preceding-sibling::W1[@w2Chunk = 'B']) = $nthB)]" mode="delete-w2-info"/>
      <xsl:apply-templates select="following-sibling::W1[@w2Chunk = 'E'][1]" mode="delete-w2-info"/> 
    </xsl:element>
  </xsl:template>

  <xsl:template match="W1" mode="delete-w2-info">
    <xsl:element name="W1">
      <xsl:for-each select="@*[not(starts-with(name(), 'w2'))]">
        <xsl:attribute name="{name()}">
          <xsl:value-of select="."/>
        </xsl:attribute>
      </xsl:for-each>
    </xsl:element>  
  </xsl:template>

  <xsl:template match="W1[@w2Chunk = 'I']" priority="10" mode="chunker">
  </xsl:template>

  <xsl:template match="W1[@w2Chunk = 'E']" priority="10" mode="chunker">
  </xsl:template>

</xsl:stylesheet>
