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
#    Usage: python3 histogram.py <Input-file> <Output-file> <bind-value> <MLoD>
#    Example: python3 histogram.py vertical_differencing_3.xyz histogram.png 10 0.5
#
#############################################################################################

import sys
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# main

if len(sys.argv) != 6:
    print ("\n\nMissing parameters:")
    print ("Usage: python3 histogram.py <Input-file> <Output-file> <bind-value> <MLoD>")
    print ("Example: python3 histogram.py vertical_differencing_3.xyz histogram.png 10 0.5 \n\n")
    exit(0)

file_xyz = sys.argv[1]
file_png = sys.argv[2]
bind_val = int(sys.argv[3])
mlod = float(sys.argv[4])
unit = sys.argv[5]

print ('Input file xyz =', file_xyz)
print ('Output file png =', file_png)
print ('bind_val =', bind_val)
print ('mlod =', mlod)
print ('unit =', unit)

topo2 = np.loadtxt(file_xyz)
dh = np.array(topo2)
dh = dh[np.logical_and(dh>-9000,dh<9000)]

#Try to get the figsize by a ratio of 400 / 450
fig, ax = plt.subplots(figsize=(6, 6.75))
n, bins, patches = ax.hist(dh,bins=range(-bind_val, bind_val),facecolor='blue', alpha=0.5)

if mlod < 0:
    ax.set_title("Vertical Differencing")
else:
    max_counts = max(n)
    plt.plot([-mlod,-mlod], [0, max_counts], 'r-')
    plt.plot([mlod,mlod], [0, max_counts], 'r-')
    ax.set_title("Vertical Differencing: Error threshold = " + str(mlod) + " " + unit)


ax.set_xlabel('Vertical difference (' + unit + ')')
ax.set_ylabel('Counts')

fig.tight_layout()
#plt.show()

plt.savefig(file_png)
plt.close(fig)
