# ebooks-migration

A tool to manage a mongodb of ebook records from various sources

## Source files
### SFX

From [SFX](http://www.exlibrisgroup.com/category/SFXOverview), export MARC21 XML files of records. It's best to export 1 file per target_service.

The result should look like this:
```
<record>
  <leader>-----nam-a2200000z--4500</leader>
  <controlfield tag="008">151119uuuuuuuuuxx-uu-|------u|----|fre-d</controlfield>
  <datafield tag="245" ind1="" ind2="0">
   <subfield code="a">Économie de la firme</subfield>
  </datafield>
  <datafield tag="260" ind1="" ind2="">
   <subfield code="c">2003</subfield>
  </datafield>
  <datafield tag="020" ind1="" ind2="">
   <subfield code="a">2-7071-3741-3</subfield>
  </datafield>
  <datafield tag="020" ind1="" ind2="">
   <subfield code="a">1-4175-5426-6</subfield>
  </datafield>
  <datafield tag="100" ind1="1" ind2="">
   <subfield code="a">Baudry, Bernard</subfield>
  </datafield>
  <datafield tag="090" ind1="" ind2="">
   <subfield code="a">1000000000448791</subfield>
  </datafield>
  <datafield tag="856" ind1="" ind2="">
   <subfield code="u">http://mybase-url.fr??url_ver=Z39.88-2004&amp;ctx_ver=Z39.88-2004&amp;ctx_enc=info:ofi/enc:UTF-8&amp;rfr_id=info:sid/sfxit.com:opac_856&amp;url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx&amp;sfx.ignore_date_threshold=1&amp;rft.object_id=1000000000448791&amp;svc_val_fmt=info:ofi/fmt:kev:mtx:sch_svc&amp;svc.fulltext=yes&amp;</subfield>
  </datafield>
  <datafield tag="866" ind1="" ind2="">
   <subfield code="i">DEFAULT</subfield>
   <subfield code="s">3240000000000058</subfield>
   <subfield code="t">3240000000000057</subfield>
   <subfield code="x">CAIRN Repères:Full Text</subfield>
   <subfield code="z">3240000000019141</subfield>
  </datafield>
 </record>
```

Relevent fields matched to our meta.json :
* title = 245a
* pub_date = 260c
* isbn = 020a
* author = 100a
* sfx_id = 090a
* openurl = 856s
* target_service = 866x, split before ":"

### publisher files

We sometimes get Excel or flat files from publishers. Each with its own format and columns.
We should have a flat_file_loader.pl with a mypublisher.yaml config file for each publisher.

## Dedupe
ISBNs are the only somewhat reliable numbers that can be used to dedupe between files. We don't always know if it's an isbn for the print or the digital version of the book. We try to store as many isbns as possible.

## Get records from [Sudoc](http://www.sudoc.abes.fr) Union Catalog
### [isbn2ppn](http://documentation.abes.fr/sudoc/manuels/administration/aidewebservices/ISBN2PPN.html)

Give an isbn, retrieve record ids from the union catalog (PPN).
Store in mongodb record

### ppn2record
 Give a PPN, retrieve the UNIMARC XML record
 Save record as a BLOB in record file in mongodb
 
 ## Keep the "best" record
 * For a given ebook
   * if a record indicates it's for a digital edition
     * flags the corresponding isbn as "primary": true
     * flag others as "primary": false
     * remove other marc blobs (?)

## meta.json
Could look like this
```
{
  "record": {
    "id": 1,
    "date_created": 144633600032132132132,
    "date_updated": 144633600032132132132,
    "record_type": "ebook",
    "active": true,
    "sfx_id": 1000000000448791,
    "sfx_last_harvest_datetime": 1446336000,
    "publisher_last_harvest_datetime": 1446336000,
    "isbn2ppn_last_harvest_datetime": 1446336000,
    "sudoc_last_harvest_datetime": 1446336000,
    "author": "Hersh, Kristin",
    "title": "Rat Girl",
    "pub_date": "2015",
    "edition": "2",
    "target_service": "Cairn Repères",
    "openurl": "http://mybase-url.fr??url_ver=Z39.88-2004&amp;ctx_ver=Z39.88-2004&amp;ctx_enc=info:ofi/enc:UTF-8&amp;rfr_id=info:sid/sfxit.com:opac_856&amp;url_ctx_fmt=info:ofi/fmt:kev:mtx:ctx&amp;sfx.ignore_date_threshold=1&amp;rft.object_id=1000000000448791&amp;svc_val_fmt=info:ofi/fmt:kev:mtx:sch_svc&amp;svc.fulltext=yes",
    "publisher_url": "http://ua.cyberlibris.com/book/10294949",
    "acquired": true,
    "isbns": [
      {
        "isbn": "978-0134567891",
        "electronic": true,
        "primary": true
      },
      {
        "isbn": "978-0143117391",
        "electronic": false,
        "primary": false
      }
    ],
    "ppns": [
      {
        "ppn": "123456789",
        "electronic": true,
        "primary": true
      },
      {
        "ppn": "123456789",
        "electronic": false,
        "primary": false
      }
    ],
    "marc": [
      "<record>...</record>",
      "<record>...</record>"
    ]
  }
}
```
