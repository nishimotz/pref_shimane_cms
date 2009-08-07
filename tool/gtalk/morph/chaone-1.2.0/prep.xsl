<?xml version="1.0" encoding="Shift_JIS"?>

<!-- XSLT stylesheet for ChaOne              -->
<!--                     for msxml and exslt -->
<!--                            ver. 1.2.0b5 -->
<!--  (0) preprocessing                      -->
<!--                2005-07-09 by Studio ARC -->
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

  <xsl:param name="ipadic" select="'no'"/>

  <xsl:variable name="ea_symbol_table" select="document('ea_symbol_table.xml')/ea_symbol_table"/>
  <xsl:variable name="pos_list" select="document('grammar.xml')"/>
  <xsl:variable name="pa_word_list" select="document('pa_word.xml')"/>
  <xsl:key name="pos" match="pos" use="@ipadic"/>
  <xsl:key name="pa_word" match="W1" use="concat(@orth, @pron, @pos)"/>

  <xsl:template match="/">
    <xsl:apply-templates select="S"/>
  </xsl:template>

  <xsl:template match="S">
    <xsl:copy>
      <xsl:apply-templates mode="prep"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="prep">
    <xsl:choose>
      <xsl:when test="@pos = '未知語'">
        <xsl:call-template name="ea-symbol-chk">
          <xsl:with-param name="orth" select="@orth"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="self::W1 and ($ipadic = 'yes')">
        <xsl:apply-templates select="." mode="ipadic"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:apply-templates select="*" mode="prep"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="W1" mode="ipadic">
    <xsl:variable name="ipa_pos" select="@pos"/>
    <xsl:variable name="uni_pos">
      <xsl:for-each select="$pos_list">
        <xsl:value-of select="key('pos',$ipa_pos)/@unidic"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="orthpronpos" select="concat(@orth, @pron, $uni_pos)"/>
    <xsl:copy>
      <xsl:for-each select="@*[name()!='pos']">
        <xsl:copy-of select="."/>
      </xsl:for-each>
      <xsl:attribute name="pos">
        <xsl:value-of select="$uni_pos"/>
      </xsl:attribute>
      <xsl:for-each select="$pa_word_list">
        <xsl:for-each select="key('pa_word',$orthpronpos)">
          <xsl:for-each select="@*[starts-with(name(), 'ipa') or starts-with(name(), 'fpa')]">
            <xsl:copy-of select="."/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:apply-templates select="*" mode="prep"/>
    </xsl:copy>
  </xsl:template>

  <!-- preprocess for unknown pos with English Alphabet -->
  <xsl:template name="ea-symbol-chk">
    <xsl:param name="orth"/>
    <xsl:variable name="hits">
      <xsl:for-each select="$ea_symbol_table/W1[starts-with($orth, @orth)]">
        <xsl:sort select="string-length(@orth)"/>
        <xsl:copy-of select="."/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="ext:node-set($hits)/W1[1]/@orth">
        <xsl:apply-templates select="ext:node-set($hits)/W1[1]" mode="ea-symbol">
          <xsl:with-param name="orgW1" select="."/>
          <xsl:with-param name="orth" select="$orth"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="."/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="W1" mode="ea-symbol">
    <xsl:param name="orgW1"/>
    <xsl:param name="orth"/>
    <xsl:choose>
      <xsl:when test="@orth">
        <xsl:copy-of select="."/>
        <xsl:if test="string-length($orth) > string-length(@orth)">
          <!-- *** recursive call *** -->
          <xsl:call-template name="ea-symbol-chk">
            <xsl:with-param name="orth" select="substring($orth, string-length(@orth) + 1)"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$orgW1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
