<?xml version="1.0" encoding="Shift_JIS"?>

<!-- XSLT stylesheet for ChaOne              -->
<!--                     for msxml and exslt -->
<!--                            ver. 1.2.0b4 -->
<!-- ChaOne consists of the followings;      -->
<!--  (2) Phonetic Alternation               -->
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

  <xsl:variable name="IPAForm_table" select="document('IPAForm.xml')/IPAForm_table"/>
  <xsl:variable name="FPAForm_table" select="document('FPAForm.xml')/FPAForm_table"/>

  <xsl:template match="/">
    <xsl:apply-templates select="S"/>
  </xsl:template>

  <xsl:template match="S">
    <xsl:copy>
      <xsl:apply-templates mode="chaone"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*|node()" mode="chaone">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" mode="chaone"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="W2[not(@pron)]" mode="chaone">
    <!-- pron属性を持たないW2に対する音韻交替処理 -->
    <!-- W2の子要素である各W1についての処理 -->
    <xsl:variable name="W1-list">
      <xsl:apply-templates select="W1" mode="alt"/>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="pron">
        <xsl:for-each select="ext:node-set($W1-list)/W1">
          <xsl:value-of select="@pron"/>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:copy-of select="$W1-list"/>
    </xsl:copy>
  </xsl:template>

  <!-- ChaOne inside W2 -->
  <xsl:template match="W1" mode="alt">
    <xsl:variable name="ipaForm">
      <xsl:if test="@ipaType">
        <xsl:call-template name="calc-ipaForm"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="fpaForm">
      <xsl:if test="@fpaType">
        <xsl:call-template name="calc-fpaForm"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="pron">
      <xsl:call-template name="calc-pron">
        <xsl:with-param name="ipaForm" select="$ipaForm"/>
        <xsl:with-param name="fpaForm" select="$fpaForm"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="string($ipaForm)">
        <xsl:attribute name="ipaForm">
          <xsl:value-of select="$ipaForm"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="string($fpaForm)">
        <xsl:attribute name="fpaForm">
          <xsl:value-of select="$fpaForm"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="string($pron)">
        <xsl:attribute name="pron">
          <xsl:value-of select="$pron"/>
        </xsl:attribute>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="calc-ipaForm">
    <!-- current() = W1 -->
    <!-- returns value of ipaForm or nothing -->
    <xsl:variable name="ipaConType" select="preceding-sibling::W1[1]/@ipaConType"/>
    <xsl:variable name="ipaType" select="@ipaType"/>
    <xsl:if test="string($ipaConType)">
      <xsl:value-of select="$IPAForm_table/IPAFormDefs[@IPAType = $ipaType]/IPAFormDef[@IPAConType = $ipaConType]/@IPAForm"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="calc-fpaForm">
    <!-- current() = W1 -->
    <!-- returns value of fpaForm or nothing -->
    <xsl:variable name="fpaConTypes" select="following-sibling::W1[1]/@fpaConType"/>
    <xsl:variable name="fpaType" select="@fpaType"/>
    <xsl:if test="string($fpaConTypes)">
      <xsl:variable name="fpaConType">
        <xsl:choose>
          <xsl:when test="contains($fpaConTypes, ',')">
            <xsl:value-of select="substring-before($fpaConTypes, ',')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$fpaConTypes"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:value-of select="$FPAForm_table/FPAFormDefs[@FPAType = $fpaType]/FPAFormDef[@FPAConType = $fpaConType]/@FPAForm"/>
    </xsl:if>
  </xsl:template>

  <xsl:template name="calc-pron">
    <!-- current() = W1 -->
    <!-- returns value of pron -->
    <xsl:param name="ipaForm"/>
    <xsl:param name="fpaForm"/>
    <xsl:call-template name="ipaForm-pron-alt">
      <xsl:with-param name="ipaForm" select="$ipaForm"/>
      <xsl:with-param name="pron">
        <xsl:call-template name="fpaForm-pron-alt">
          <xsl:with-param name="fpaForm" select="$fpaForm"/>
          <xsl:with-param name="pron" select="@pron"/>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="ipaForm-pron-alt">
    <!-- current() = W1 -->
    <!-- returns value of pron -->
    <xsl:param name="ipaForm"/>
    <xsl:param name="pron"/>
    <xsl:variable name="ipaType" select="@ipaType"/>
    <xsl:choose>
      <xsl:when test="string($ipaForm)">
        <xsl:call-template name="alt-head">
          <xsl:with-param name="pron" select="$pron"/>
          <xsl:with-param name="len" select="string-length($IPAForm_table/IPAFormDefs[@IPAType = $ipaType]/IPApronDef[@IPAForm = '基本形']/@pron)"/>
          <xsl:with-param name="alt" select="$IPAForm_table/IPAFormDefs[@IPAType = $ipaType]/IPApronDef[@IPAForm = $ipaForm]/@pron"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$pron"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="fpaForm-pron-alt">
    <!-- current() = W1 -->
    <!-- returns value of pron -->
    <xsl:param name="fpaForm"/>
    <xsl:param name="pron"/>
    <xsl:variable name="fpaType" select="@fpaType"/>
    <xsl:choose>
      <xsl:when test="string($fpaForm)">
        <xsl:call-template name="alt-tail">
          <xsl:with-param name="pron" select="$pron"/>
          <xsl:with-param name="len" select="string-length($FPAForm_table/FPAFormDefs[@FPAType = $fpaType]/FPApronDef[@FPAForm = '基本形']/@pron)"/>
          <xsl:with-param name="alt" select="$FPAForm_table/FPAFormDefs[@FPAType = $fpaType]/FPApronDef[@FPAForm = $fpaForm]/@pron"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$pron"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="alt-head">
    <xsl:param name="pron"/>
    <xsl:param name="len"/>
    <xsl:param name="alt"/>
    <xsl:value-of select="$alt"/>
    <xsl:value-of select="substring($pron, number($len) + 1)"/>
  </xsl:template>

  <xsl:template name="alt-tail">
    <xsl:param name="pron"/>
    <xsl:param name="len"/>
    <xsl:param name="alt"/>
    <xsl:value-of select="substring($pron, 1, string-length($pron) - number($len))"/>
    <xsl:value-of select="$alt"/>
  </xsl:template>

</xsl:stylesheet>
