# Copyright (c) 2014, MapR Technologies
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

import argparse
import collections as c
import itertools as _iter
import operator as op
import os
import re
import sys


spec = {
    'asynchbase': 1, 'cascading': 1, 'flume': 1, 'hbase': 1,
    'hbasethrift': 1, 'hcatalog': 1, 'hive': 2, 'hivemetastore': 2,
    'hiveserver2': 2, 'httpfs': 1, 'hue': 1, 'impala': 1, 'mahout': 1,
    'oozie': 2, 'pig': 1, 'spark': 1, 'sqoop': 0, 'sqoop2': 1, 'whirr': 1
}

reg_expr = ur"mapr-([a-z]+\d?)[-_]([a-z]+)?[-_]?(\d+).(\d+).(\d+).(\d+)?"
pattern = re.compile(reg_expr)

file_map = c.defaultdict(list)
version_map = c.defaultdict(list)
comp_map = c.defaultdict(tuple)


def parse_filename(args):
    def mapper(arg):
        try:
            new_int = int(arg)
            return new_int
        except ValueError:
            return arg
        except TypeError:
            pass

    def predicate(_type):
        return lambda x: isinstance(x, _type)

    arg_list = filter(lambda x: op.is_not(x, None),
                      map(mapper, args))

    pair = (tuple(filter(predicate(str), arg_list)),
            filter(predicate(int), arg_list))

    return pair


def main(arg_list):
    if os.path.exists(arg_list.path):
        for f_name in os.listdir(arg_list.path):
            match = pattern.match(f_name)
            if match:
                file_map[f_name] = parse_filename(match.groups())

        for k, g in _iter.groupby(file_map.values(),
                                  key=lambda i: op.getitem(i, 0)):
            for elem in g:
                version_map[k].append(op.getitem(elem, 1))

        for (k, v) in version_map.items():
            comp_map[k] = sorted(v, reverse=True)[:spec.get(k[0], 1)]

        version_spec = set()

        with open(arg_list.spec_file, mode='w') as f:
            not_build_version = lambda a: len(str(a)) < 3
            for k, v in comp_map.items():
                join_versions = lambda seq: '.'.join(
                    str(el) for el in filter(not_build_version, seq))
                v_str = ','.join(map(join_versions, v))
                version_spec.add('{comp:s} = {versions:s}\n'
                                 .format(**{'comp': k[0], 'versions': v_str}))
            f.writelines(version_spec)

        for (f_name, comp) in file_map.items():
            if not comp[1] in comp_map[comp[0]]:
                target = os.path.join(arg_list.path, f_name)
                sys.stdout.write(str(target).strip() + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--path', help='path to repository files')
    parser.add_argument('--spec-file', help='path to specification files')
    args = parser.parse_args()
    if not args.path or not args.spec_file:
        parser.print_help()
        exit(-1)
    main(args)
