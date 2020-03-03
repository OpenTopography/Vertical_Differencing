#!/opt/python/bin/python -u

#############################################################################################
# LICENSE
#
# Copyright (c) 2007 The Regents of the University of California# 
# 
# Permission to use, copy, modify, and distribute this software and its documentation
# for educational, research and non-profit purposes, without fee, and without a written
# agreement is hereby granted, provided that the above copyright notice, this
# paragraph and the following three paragraphs appear in all copies.
# 
# Permission to make commercial use of this software may be obtained
# by contacting:
# Technology Transfer Office
# 9500 Gilman Drive, Mail Code 0910
# University of California
# La Jolla, CA 92093-0910
# (858) 534-5815
# invent@ucsd.edu
# 
# THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
# NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#############################################################################################

#############################################################################################
# USAGE:
#
#    python3 vertical_differencing_colorbar.py <stddevVal> <unit> <Output-file>
#    Example: python3 vertical_differencing_colorbar.py 4.91 m colorbar.png
#
#############################################################################################

import sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

if len(sys.argv) != 4:
    print ("\n\nMissing parameters:")
    print ("Usage: python3 vertical_differencing_colorbar.py <stddevVal> <unit> <Output-file>")
    print ("Example: python3 vertical_differencing_colorbar.py 4.91 m colorbar.png\n\n")
    exit(0)

stddevVal = float(sys.argv[1])
unit = sys.argv[2]
file_png = sys.argv[3]

print ('stddevVal =', stddevVal)
print ('unit =', unit)
print ('file_png =', file_png)

fig, ax = plt.subplots(figsize=(6, 1))

#Try to get the figsize by a ratio of 400 / 450
#fig, ax = plt.subplots(figsize=(6, 6.75))

fig.subplots_adjust(bottom=0.5)
cmap = matplotlib.cm.bwr_r

print (cmap)

norm = matplotlib.colors.Normalize(vmin=-stddevVal, vmax=stddevVal)
cb1 = matplotlib.colorbar.ColorbarBase(ax, cmap=cmap, norm=norm, orientation='horizontal')
cb1.set_label('Vertical difference (' + unit + ')')

#fig.tight_layout()
#fig.show()

plt.savefig(file_png)
plt.close(fig)


