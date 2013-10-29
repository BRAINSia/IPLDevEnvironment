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
import unittest
from tempfile import NamedTemporaryFile


class ConvertCMakeCacheTest(unittest.TestCase):
    def setUp(self):
        self.maxDiff = None  # Allow failures to print on testing
        test_string = """
# You can edit this file to change values found and used by cmake.
# The syntax for the file is as follows:
# KEY:TYPE=VALUE
# KEY is the name of a variable in the cache.
# TYPE is a hint to GUI's for the type of VALUE, DO NOT EDIT TYPE!.
# VALUE is the current value for the KEY.

########################
# EXTERNAL cache entries
########################

//path to the bison executable
BISON_EXECUTABLE:FILEPATH=/usr/bin/bison

//Flags used by bison
BISON_FLAGS:STRING=

//Build uncrustify, cppcheck, & KWStyle
BUILD_STYLE_UTILS:BOOL=ON

//Build the testing tree.
BUILD_TESTING:BOOL=ON

//Flags used by the compiler during release builds (/MD /Ob1 /Oi
// /Ot /Oy /Gs will produce slightly less optimized but smaller
// files).
CMAKE_CXX_FLAGS_RELEASE:STRING=-O3 -DNDEBUG

//Install path prefix, prepended onto install directories.
CMAKE_INSTALL_PREFIX:PATH=/usr/local

// Value Computed by CMake
CMAKE_PROJECT_NAME:STATIC = SuperBuild_NAMICExternalProjects

// Value Computed by CMake
CMAKE_PROJECT_NAME:STATIC=SuperBuild_NAMICExternalProjects

//Path to a program.
QT_RCC_EXECUTABLE:FILEPATH=/usr/local/Cellar/qt/4.8.5/bin/rcc
"""
        self.tempfile = NamedTemporaryFile(mode='r+w+b', prefix='CMakeCache', suffix='.txt')
        self.tempfile.write(test_string)
        self.tempfile.flush()
        self.expected = ["",
                         "# You can edit this file to change values found and used by cmake.",
                         "# The syntax for the file is as follows:",
                         "# KEY:TYPE=VALUE",
                         "# KEY is the name of a variable in the cache.",
                         "# TYPE is a hint to GUI's for the type of VALUE, DO NOT EDIT TYPE!.",
                         "# VALUE is the current value for the KEY.",
                         "########################",
                         "# EXTERNAL cache entries",
                         "########################",
                         "",
                         "//path to the bison executable",
                         "BISON_EXECUTABLE:FILEPATH=/usr/bin/bison",
                         "",
                         "//Flags used by bison",
                         "BISON_FLAGS:STRING=",
                         "",
                         "//Build uncrustify, cppcheck, & KWStyle",
                         "BUILD_STYLE_UTILS:BOOL=ON",
                         "",
                         "//Build the testing tree.",
                         "BUILD_TESTING:BOOL=ON",
                         "",
                         "//Flags used by the compiler during release builds (/MD /Ob1 /Oi",
                         "// /Ot /Oy /Gs will produce slightly less optimized but smaller",
                         "// files).",
                         "CMAKE_CXX_FLAGS_RELEASE:STRING=-O3 -DNDEBUG",
                         "",
                         "//Install path prefix, prepended onto install directories.",
                         "CMAKE_INSTALL_PREFIX:PATH=/usr/local",
                         "",
                         "// Value Computed by CMake",
                         "CMAKE_PROJECT_NAME:STATIC = SuperBuild_NAMICExternalProjects",
                         "",
                         "// Value Computed by CMake",
                         "CMAKE_PROJECT_NAME:STATIC=SuperBuild_NAMICExternalProjects",
                         "",
                         "//Path to a program.",
                         "QT_RCC_EXECUTABLE:FILEPATH=/usr/local/Cellar/qt/4.8.5/bin/rcc",
                         ""]
        self.final = ['set( BISON_EXECUTABLE "/usr/bin/bison" CACHE FILEPATH "//path to the bison executable" )',
                      'set( BISON_FLAGS "" CACHE STRING "//Flags used by bison" )',
                      'set( BUILD_STYLE_UTILS "ON" CACHE BOOL "//Build uncrustify, cppcheck, & KWStyle" )',
                      'set( BUILD_TESTING "ON" CACHE BOOL "//Build the testing tree." )',
                      'set( CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG" CACHE STRING "// files)." )',
                      'set( CMAKE_INSTALL_PREFIX "/usr/local" CACHE PATH "//Install path prefix, prepended onto install directories." )',
                      'set( QT_RCC_EXECUTABLE "/usr/local/Cellar/qt/4.8.5/bin/rcc" CACHE FILEPATH "//Path to a program." )']

    def test_readCMakeCache(self):
        actual = readCMakeCache(self.tempfile.name)
        self.assertItemsEqual(self.expected, actual)

    def test_updateCache(self):
        try:
            final = updateCache(self.expected)
        except:
            raise
        self.assertItemsEqual(self.final, final)


def readCMakeCache(filename):
    """
    Read and format the CMakeCache file for usage

    @param filename:
    @type filename:
    @return:
    @rtype:
    """
    with open(filename, 'r') as ff:
        content = [x.strip() for x in ff.readlines()]
    return content


def updateCache(content):
    content_pattern = re.compile(r'^([^:]*):([^=]*)=(.*)')
    final = []
    last_comment = ''
    for line in content:
        if line == "":
            #print("EMPTY:")
            pass
        elif line[0] == '#' or line[0] == '/':
            #print("COMMENT: {0}".format(line))
            last_comment = line.rstrip('/')
            pass
        else:
            #CMAKE_VERBOSE_MAKEFILE-ADVANCED:INTERNAL=1
            #set( CMAKE_BUILD_TYPE             "RelWithDebInfo" CACHE STRING "")
            #print("CONTENT: {0}".format(line))
            this_var = content_pattern.sub(r'\1',line).strip()
            this_val = content_pattern.sub(r'\3',line).strip()
            this_typ = content_pattern.sub(r'\2',line).strip()
            if this_typ == 'INTERNAL' or this_typ == 'STATIC':
                continue
            final.append('set( {0} "{1}" CACHE {2} "{3}" )'.format(this_var, this_val, this_typ, last_comment))
    return final



if __name__ == "__main__":
    if len(sys.argv) == 1:
        import doctest
        suite = unittest.TestLoader()
        suite.loadTestsFromTestCase(ConvertCMakeCacheTest)
        unittest.main(testLoader=suite)
        # doctest.testmod()

    else:
        content = readCMakeCache(sys.argv[1])
        print updateCache(content)