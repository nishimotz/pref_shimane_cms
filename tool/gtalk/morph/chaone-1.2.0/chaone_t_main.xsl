<?xml version="1.0"?>

<!-- XSLT stylesheet for ChaOne              -->
<!--                     for msxml and exslt -->
<!--                            ver. 1.2.0b5 -->
<!-- ChaOne consists of the followings;      -->
<!--  (0) preprocessing                      -->
<!--  (1) ChaSen Chunker                     -->
<!--  (2) Phonetic Alternation               -->
<!--  (3) Accent Combination                 -->
<!--                2005-07-09 by Studio ARC -->
<!-- Copyright (c) 2004-2005 Studio ARC      -->

<!-- This program is based on the product    -->
<!--   developed in IPA project 1999-2002    -->

<!-- [how to set]                            -->
<!-- if you are using msxml,                 -->
<!--   set the namespace prefix "ext"        -->
<!--     similarly to prefix "msxml"         -->
<!-- if you are using exslt,                 -->
<!--   set the namespace prefix "ext"        -->
<!--     similarly to prefix "exsl"          -->
<!-- set the encoding of xsl:output properly -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exsl="http://exslt.org/common"
  xmlns:msxml="urn:schemas-microsoft-com:xslt"
  xmlns:ext="http://exslt.org/common"
  extension-element-prefixes="exsl msxml ext"
  exclude-result-prefixes="exsl msxml ext"
  version="1.0"
  xml:lang="ja">

  <xsl:import href="prep.xsl"/>
  <xsl:import href="chunker.xsl"/>
  <xsl:import href="phonetic.xsl"/>
  <xsl:import href="accent.xsl"/>

  <xsl:output method="xml" encoding="EUC-JP" omit-xml-declaration="yes" indent="yes"/>

  <xsl:param name="standalone"/>
  <xsl:param name="debug"/>
  <xsl:param name="ipadic" select="'yes'"/>
  <xsl:param name="michigo" select="'yes'"/>

  <xsl:variable name="ea_symbol_table" select="document('ea_symbol_table.xml')/ea_symbol_table"/>
  <xsl:variable name="chunk_rules" select="document('chunk_rules.xml')/chunk_rules"/>
  <xsl:variable name="IPAForm_table" select="document('IPAForm.xml')/IPAForm_table"/>
  <xsl:variable name="FPAForm_table" select="document('FPAForm.xml')/FPAForm_table"/>
  <xsl:variable name="pos_list" select="document('grammar.xml')"/>
  <xsl:variable name="pa_word_list" select="document('pa_word.xml')"/>
  <xsl:key name="pos" match="pos" use="@ipadic"/>
  <xsl:key name="pa_word" match="W1" use="concat(@orth, @pron, @pos)"/>
  <xsl:variable name="ap_rule" select="document('ap_rule.xml')/ap_rule/rule"/>
  <xsl:variable name="accent_rule" select="document('accent_rule.xml')/aType_rule/rule"/>
  <xsl:variable name="kannjiyomi" select="document('kannjiyomi.xml')/kannjiyomi/char"/>

  <xsl:template match="/">
    <xsl:if test="$debug">
      <xsl:message>
        <xsl:text>INPUT:
</xsl:text>
        <xsl:apply-templates select="." mode="text"/>
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="S"/>
  </xsl:template>

  <xsl:template match="S">
    <xsl:copy>
      <xsl:choose>
        <xsl:when test="$standalone = 'prep'">
          <xsl:apply-templates mode="prep"/>
        </xsl:when>
        <xsl:when test="$standalone = 'chunker'">
          <xsl:apply-templates mode="chunker"/>
        </xsl:when>
        <xsl:when test="$standalone = 'chaone'">
          <xsl:apply-templates mode="chaone"/>
        </xsl:when>
        <xsl:when test="$standalone = 'accent'">
          <xsl:variable name="ws">
            <xsl:apply-templates mode="preap"/>
          </xsl:variable>
          <xsl:apply-templates select="ext:node-set($ws)/*[1]" mode="mainap">
            <xsl:with-param name="stack" select="0"/>
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="preps">
            <preps>
              <xsl:apply-templates mode="prep"/>
            </preps>
          </xsl:variable>
          <xsl:if test="$debug">
            <xsl:message>
              <xsl:text>PreProcess:
</xsl:text>
              <xsl:apply-templates select="ext:node-set($preps)" mode="text"/>
            </xsl:message>
          </xsl:if>
          <xsl:variable name="chunk">
            <xsl:apply-templates select="ext:node-set($preps)/preps/*" mode="chunker"/>
          </xsl:variable>
          <xsl:if test="$debug">
            <xsl:message>
              <xsl:text>Chunker:
</xsl:text>
              <xsl:apply-templates select="ext:node-set($chunk)" mode="text"/>
            </xsl:message>
          </xsl:if>
          <xsl:variable name="pa">
              <xsl:apply-templates select="ext:node-set($chunk)/*" mode="chaone"/>
          </xsl:variable>
          <xsl:if test="$debug">
            <xsl:message>
              <xsl:text>Phonetic Alternation:
</xsl:text>
              <xsl:apply-templates select="ext:node-set($pa)" mode="text"/>
            </xsl:message>
          </xsl:if>
          <xsl:variable name="ws">
            <xsl:apply-templates select="ext:node-set($pa)/*" mode="preap"/>
          </xsl:variable>
          <xsl:apply-templates select="ext:node-set($ws)/*[1]" mode="mainap">
            <xsl:with-param name="stack" select="0"/>
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="text">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:for-each select="@*">
      <xsl:value-of select="concat(' ', name(), '=&quot;', string(), '&quot;')"/>
    </xsl:for-each>
    <xsl:choose>
      <xsl:when test="*">
        <xsl:text>&gt;</xsl:text>
        <xsl:apply-templates mode="text"/>
        <xsl:text>&lt;/</xsl:text>
        <xsl:value-of select="name()"/>
        <xsl:text>&gt;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>/&gt;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
