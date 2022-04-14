#!/usr/bin/env python

import hashlib
import os
import sys
from panflute import toJSONFilter, Para, Image, CodeBlock, Str
from subprocess import Popen, PIPE, call
from tempfile import mkdtemp

imagedir = "tchart-images"


def sha1(x):
    return hashlib.sha1(x.encode(sys.getfilesystemencoding())).hexdigest()


def tc2image(tc, outfile):
    # ファイルを作成する
    with open(imagedir + '/' + 'tmp.tc', mode='w') as f:
        f.write(tc)

    call(["./tchart.pl", imagedir + '/tmp.tc', outfile], stdout=sys.stderr)


def tchart(elem, doc):
    if type(elem) == CodeBlock and 'tchart' in elem.classes:
        code = elem.text
        caption = "caption"

        filename = sha1(code)
        # {'html': 'png', 'latex': 'pdf'}.get(doc.format, 'png')
        filetype = 'eps'
        alt = Str(caption)
        src = imagedir + '/' + filename + '.' + filetype
        if not os.path.isfile(src):
            try:
                os.mkdir(imagedir)
                sys.stderr.write('Created directory ' + imagedir + '\n')
            except OSError:
                pass

            tc2image(code, src)

            sys.stderr.write('Created image ' + src + '\n')

        return Para(Image(alt, url=src, title=''))


if __name__ == "__main__":
    toJSONFilter(tchart)
