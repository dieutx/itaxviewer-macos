// msxml_oracle.js — render oracle cho iTax Viewer (Windows)
//
// Chay XSLT cua ban cai goc bang dung engine ma app dung: MSXML 3.0 qua
// XSLTemplate + FreeThreadedDOMDocument, tuc la cung duong di ma
// data/run.html goi (ActiveXObject("Microsoft.XMLDOM") -> transformNode).
// Nho vay co HTML tham chieu ma khong can mo GUI, khong doi registry.
//
// Dung:
//   cscript //nologo msxml_oracle.js <ho-so.xml> <mau.xslt> <ra.html>
//
// Vi du:
//   cscript //nologo msxml_oracle.js ^
//     "C:\samples\01GTGT.xml" ^
//     "C:\Program Files (x86)\iTax Viewer\data\xslt\TKhaiThue\xslt\GTGT\TKhai_GTGT_01_TT80.xslt" ^
//     "C:\tmp\01GTGT.oracle.html"
//
// Ghi chu da kiem chung 2026-10-23:
//  - xsl:include/xsl:import duoc resolve theo duong dan tuong doi cua mau -> phai
//    tro vao dung cay XSLT cua ban cai (khong copy le tung tep).
//  - msxsl:script (JScript) chay duoc, nhung cac ham trong common.xsl dung
//    node.nextNode() cua DOM IE; goi bang chuoi ("ihtkk:formatNumber('123')")
//    se loi "Object doesn't support this property or method". Chi goi bang node-set.
//  - File ra la UTF-16 (giong app that). Doc lai bang utf-16.
//  - Chua chay buoc hau xu ly `$('.number').each(...)` cua run.html; neu can
//    HTML cuoi cung thi phai ap them buoc do (port formatNumber tu data/js).

var args = WScript.Arguments;
if (args.length < 3) {
  WScript.Echo("usage: cscript //nologo msxml_oracle.js <input.xml> <style.xslt> <out.html>");
  WScript.Quit(1);
}
var xmlPath = args(0), xslPath = args(1), outPath = args(2);

var xml = new ActiveXObject("Msxml2.DOMDocument.3.0");
xml.async = false;
if (!xml.load(xmlPath)) {
  WScript.Echo("LOAD XML FAIL line " + xml.parseError.line + ": " + xml.parseError.reason);
  WScript.Quit(2);
}

var xsl = new ActiveXObject("Msxml2.FreeThreadedDOMDocument.3.0");
xsl.async = false;
if (!xsl.load(xslPath)) {
  WScript.Echo("LOAD XSL FAIL line " + xsl.parseError.line + ": " + xsl.parseError.reason);
  WScript.Quit(3);
}

var template = new ActiveXObject("Msxml2.XSLTemplate.3.0");
template.stylesheet = xsl;
var processor = template.createProcessor();
processor.input = xml;
try {
  processor.transform();
} catch (err) {
  WScript.Echo("TRANSFORM FAIL: " + err.message);
  WScript.Quit(4);
}

var html = processor.output;
var fso = new ActiveXObject("Scripting.FileSystemObject");
var file = fso.CreateTextFile(outPath, true, true); // true = overwrite, true = unicode
file.Write(html);
file.Close();
WScript.Echo("OK chars=" + html.length + " -> " + outPath);
