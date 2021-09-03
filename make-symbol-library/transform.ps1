# Transform the svg files containing individual symbols into an
# Inkscape symbol library using make-symbols.xsl. Worked in 2021 on a
# Windows Server 2016 machine with Powershell 5. Might work with
# PowerShell Core on a Linux machine.
#
# To use: Change directories into the affinity directory, then run
# this script from there, e.g. make-symbol-library\transform.ps1. No
# parameters are necessary. After the script is done, take the SVG
# file named by the $out_svg variable below, and place it into your
# Inkscape symbols directory:
# e.g. c:\users\yourname\appdata\roaming\inkscape\symbols, or perhaps
# ~/.local/share/inkscape/symbols. See also
# https://wiki.inkscape.org/wiki/index.php/SymbolsDialog.

function filename_to_id($filename) {
    # In this particular set of files, every filename is unique:
    # circle\blue\*.svg are named c_*_blue.svg, making the directory
    # path redundant. So a unique identifier only needs the file's
    # basename. But we keep it so that everything will sort properly.
    $keep_dirs_in_id = $true
    if($keep_dirs_in_id) {
        $x = Resolve-Path $filename -relative
        $x = $x -replace "^.\\",""
        $x = $x -replace "^svg\\",""
    } else {
        $x = Split-Path -Leaf $filename
    }
    $x = $x -replace "\.svg$",""
    $x = $x -replace "[^A-Za-z0-9]","_"
    $x
}

# started from https://mwallner.net/2017/03/31/merging-xml-with-xslt-and-powershell-ok/
$xsltfile = Join-Path $PSScriptRoot "make-symbols.xsl"
$svg_list_xml = Join-Path $(Get-Location) "svg-list.xml"
$out_svg = Join-Path $(Get-Location) "affinity-network-symbols.svg"
$svg_dir = Join-Path $(Get-Location) "svg"

write-output "Gathering SVGs under $svg_dir"

$XsltSettings = New-Object System.Xml.Xsl.XsltSettings
$XsltSettings.EnableDocumentFunction = 1

$xslt = New-Object System.Xml.Xsl.XslCompiledTransform;
$xslt.Load($xsltfile , $XsltSettings, $(New-Object System.Xml.XmlUrlResolver))

# https://petri.com/creating-custom-xml-net-powershell
[xml] $filelist = New-Object System.Xml.XmlDocument
$filelist.AppendChild($filelist.CreateXmlDeclaration("1.0", "UTF-8", $null)) | out-null
$files = $filelist.CreateNode("element", "files", $null)
$ngathered = 0
foreach($fn in (Get-ChildItem -r -file $svg_dir/*.svg | select -expand Fullname )) {
    $f = $filelist.CreateElement("file", $null)
    $f.InnerText = $fn
    $id_att = $filelist.CreateAttribute("id", $null)
    $id_att.Value = filename_to_id($fn)
    $f.Attributes.Append($id_att) | out-null
    $files.AppendChild($f) | out-null
    $ngathered += 1
}
$filelist.AppendChild($files) | out-null
$filelist.save($svg_list_xml)

[System.Xml.XmlReaderSettings] $settings = [System.Xml.XmlReaderSettings]::new()
$settings.DtdProcessing = [System.Xml.DtdProcessing]::Ignore
[System.Xml.XmlReader]$file_list_reader = [System.Xml.XmlReader]::Create($svg_list_xml, $settings)
[System.Xml.XmlWriter]$xmlwriter = [System.Xml.XmlWriter]::Create($out_svg)
try {
    $xslt.Transform($file_list_reader, $xmlwriter)
    Write-Output "Gathered $ngathered symbols"
    Write-Output "Symbol library written to $out_svg"
} catch {
    $e = $_
    while($e.innerexception) {
      $e = $e.innerexception
    }
    throw $e
} finally {
    $xmlwriter.close()
    $file_list_reader.close()
}
