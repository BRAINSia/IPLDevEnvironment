#\author Hans J. Johsnon
#
# A script to convert CMakeCache.txt file to input cache file
# This is useful for testing minor changes, or for ensuring that
# compiler options are consistently set for multiple source trees
#STEP 1: Covert reference CMakeCache.txt
#        /usr/bin/python ConvertCMakeCache.py CMakeCache.txt > NEW_CACHE
#STEP 2: cd to new build directory
#        cd ../NewBuildDirectory
#STEP 3: Initial Cache setting
#        cmake -C NEW_CACHE ${SOURCE_TREE}
#STEP 4: run gui version of to manually fine tune settings
#        ccmake .
import sys
import re
content_pattern=re.compile(r'^([^:]*):([^=]*)=(.*)')
with open(sys.argv[1],'r') as ff:
        content = [ x.rstrip().lstrip() for x in  ff.readlines() ]
last_comment=''
for line in content:
        if line == "":
                #print("EMPTY:")
                pass
        elif line[0] == '#' or line[0] == '/':
                #print("COMMENT: {0}".format(line))
                last_comment=line.rstrip('/')
                pass
        else:
                #CMAKE_VERBOSE_MAKEFILE-ADVANCED:INTERNAL=1
                #set( CMAKE_BUILD_TYPE             "RelWithDebInfo" CACHE STRING "")
                #print("CONTENT: {0}".format(line))
                this_var=content_pattern.sub(r'\1',line)
                this_val=content_pattern.sub(r'\3',line)
                this_typ=content_pattern.sub(r'\2',line)
                if this_typ == 'INTERNAL' or this_typ == 'STATIC':
                        continue
                print('set( {0} "{1}" CACHE {2} "{3}")'.format(this_var,this_val,this_typ,last_comment))
                pass
