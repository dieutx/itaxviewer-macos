import tempfile
import unittest
from pathlib import Path

from extract_xslt_specs import extract


class ExtractorRegressionTests(unittest.TestCase):
    def extract_text(self, body):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / "synthetic.xslt"
            source.write_text('<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" '
                              'xmlns:ihtkk="urn:synthetic" version="1.0"><xsl:template match="/">'
                              + body + '</xsl:template></xsl:stylesheet>', encoding="utf-8")
            return extract(source)

    def test_totals_outside_table_keep_order_without_parent_duplicates(self):
        result = self.extract_text('''<div><table><tr><td>STT</td><td>Chỉ tiêu</td><td>Số tiền</td></tr>
        <tr><td>1</td><td>Doanh thu [21]</td><td><xsl:value-of select="ihtkk:formatNumber($tkchinh/ct21)"/></td></tr></table>
        <div><b>Tổng doanh thu [32]=[21]+[30]</b><xsl:value-of select="ihtkk:formatNumber($tkchinh/ct32)"/></div>
        <p>Tổng thuế [33]=[31]<xsl:value-of select="$tkchinh/ct33"/></p></div>''')
        rows = result["rows"]
        self.assertEqual(len(rows), 3)
        self.assertEqual([row["indicator"] for row in rows[-2:]], ["32", "33"])
        self.assertEqual(rows[-2]["values"], [{"root": "tkchinh", "path": "ct32"}])

    def test_total_label_is_not_replaced_by_its_longer_formula(self):
        result = self.extract_text('''<table><tr><td>STT</td><td>Chỉ tiêu</td><td>Mã chỉ tiêu</td></tr>
        <tr><td></td><td class="align-l">Tổng</td><td>[30]=[22]+[24]+[26]+[28]</td>
        <td><xsl:value-of select="$tkchinh/ct30"/></td></tr></table>''')
        self.assertEqual(result["rows"][0]["label"], "Tổng")
        self.assertEqual(result["rows"][0]["indicator"], "30")

    def test_fields_inside_table_are_not_added_twice(self):
        result = self.extract_text('''<table><tr><td>STT</td><td>Chỉ tiêu</td></tr>
        <tr><td>1</td><td><div>Thuế [11]<xsl:value-of select="$tkchinh/ct11"/></div></td></tr></table>''')
        self.assertEqual(len(result["rows"]), 1)
        self.assertNotIn("origin", result["rows"][0])

    def test_financial_numeric_code_preserves_leading_zeros_in_code_column(self):
        result = self.extract_text('''<table><tr><td>STT</td><td>Chỉ tiêu</td><td>Mã số</td><td>Số cuối năm</td></tr>
        <tr><td>I</td><td>Tiền</td><td>01</td><td><xsl:value-of select="$tkchinh/SoCuoiNam/ct01"/></td></tr></table>''')
        self.assertEqual(result["rows"][0]["indicator"], "01")
        self.assertEqual(result["rows"][0]["label"], "Tiền")

    def test_conditional_placeholders_and_currency_are_not_part_of_the_label(self):
        result = self.extract_text('''<div>Tổng doanh thu ([32] =[21]+[30]):
        <xsl:if test="$tkchinh/ct32 != ''"><xsl:value-of select="ihtkk:formatNumber($tkchinh/ct32)"/></xsl:if>
        <xsl:if test="$tkchinh/ct32 = ''">..........</xsl:if> Đồng Việt Nam.</div>''')
        self.assertEqual(result["rows"][0]["label"], "Tổng doanh thu ([32] =[21]+[30]):")
        self.assertEqual(result["rows"][0]["indicator"], "32")


if __name__ == "__main__":
    unittest.main()
