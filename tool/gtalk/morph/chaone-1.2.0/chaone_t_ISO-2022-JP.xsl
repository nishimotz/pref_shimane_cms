<!-- XSLT stylesheet for ChaOne                 -->
<!--   stylesheet loader for ISO-2022-JP output -->
<!--                        for msxml and exslt -->
<!--                               ver. 1.2.0b4 -->
<!--                   2005-03-27 by Studio ARC -->
<!-- Copyright (c) 2004-2005 Studio ARC         -->

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0"
  xml:lang="ja">

  <xsl:import href="chaone_t_main.xsl"/>
  <xsl:variable name="encoding" select="'ISO-2022-JP'"/>
  <xsl:output method="xml" encoding="ISO-2022-JP" omit-xml-declaration="yes" indent="yes"/>

</xsl:stylesheet>
