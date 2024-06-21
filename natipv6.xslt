<xsl:stylesheet version="1.0"
 xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
 <xsl:output omit-xml-declaration="yes" indent="yes"/>
 <xsl:strip-space elements="*"/>

<xsl:template match="forward[not(nat)]">
 <forward mode='nat'>
  <nat ipv6='yes'>
   <port start='1024' end='65535'/>
  </nat>
 <xsl:apply-templates/>
 </forward>
</xsl:template>

 <xsl:template match="node()|@*">
  <xsl:copy>
   <xsl:apply-templates select="node()|@*"/>
  </xsl:copy>
 </xsl:template>

 <xsl:template match="nat">
  <nat ipv6='yes'>
   <xsl:apply-templates select="@*|node()"/>
  </nat>
 </xsl:template>
</xsl:stylesheet>
