#!/usr/bin/env python3
"""List or remove one project's machine-local settings files.

Two tiers, deliberately not treated the same way:

  disposable  any *.local.yml.bak file, left behind by `make settings
              FORCE=1`, plus any leftover settings-reference.local.yml from
              a retired generator mode. Both regenerate or are recreated by
              `make settings`, so removing them loses nothing irreplaceable.

  active      any *.local.yml except the retired settings-reference file.
              Each holds real, hand-built configuration - hosts, credentials,
              instance definitions - that took real work to create. They are
              gitignored on purpose, so git does not back them up either:
              removing one is not reversible.

Default action is --list: print what exists in each tier and remove nothing.
--remove-disposable deletes only the disposable tier.
--remove-active deletes the disposable tier AND either one --output file
or every active *.local.yml when --output is omitted.
Neither flag ever touches a file outside these two tiers.
"""

import argparse
import glob
import os
import sys


def find_files(vars_dir):
    disposable = sorted(
        glob.glob(os.path.join(vars_dir, 'settings-reference.local.yml'))
        + glob.glob(os.path.join(vars_dir, '*.local.yml.bak'))
    )
    all_local = sorted(glob.glob(os.path.join(vars_dir, '*.local.yml')))
    active = [
        path for path in all_local
        if os.path.basename(path) != 'settings-reference.local.yml'
    ]
    return disposable, active


def resolve_output_path(vars_dir, output):
    if os.path.isabs(output) or os.path.exists(output):
        return os.path.normpath(output)
    return os.path.normpath(os.path.join(vars_dir, os.path.basename(output)))


def list_files(vars_dir, disposable, active):
    if not disposable and not active:
        print(f"{vars_dir}: no local settings files found. Nothing to clean.")
        return

    print(f"{vars_dir}: found these local settings files.")
    if disposable:
        print("  Backup files (safe to delete):")
        for f in disposable:
            print(f"    {f}")
    if active:
        print("  Active files (your real settings; git does not save them):")
        for f in active:
            print(f"    {f}")
    print()
    if disposable:
        print("Delete backup files with: make settings-clean-force")
    if active:
        print("Delete one active file with:")
        print("  make settings-clean-force-all LOCAL_SETTINGS_FILE=<path>")
        print("That cannot be undone. Copy anything you cannot recreate first.")


def remove_files(files):
    removed = []
    for f in files:
        os.remove(f)
        removed.append(f)
    return removed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--vars-dir', required=True)
    parser.add_argument('--remove-disposable', action='store_true',
                         help='Delete *.local.yml.bak files and any leftover '
                              'settings-reference.local.yml. Never touches '
                              'active *.local.yml files.')
    parser.add_argument('--remove-active', action='store_true',
                         help='Delete the disposable tier AND either --output '
                              'or every active *.local.yml. Not reversible.')
    parser.add_argument('--output',
                         help='When --remove-active, delete only this '
                              '*.local.yml file instead of every active file.')
    args = parser.parse_args()

    disposable, active = find_files(args.vars_dir)

    if not args.remove_disposable and not args.remove_active:
        list_files(args.vars_dir, disposable, active)
        return 0

    removed = remove_files(disposable)
    if args.remove_active:
        if args.output:
            target = resolve_output_path(args.vars_dir, args.output)
            if not target.endswith('.local.yml'):
                sys.stderr.write(
                    f"{target} is not a *.local.yml file; refusing to delete.\n")
                return 1
            if os.path.exists(target):
                removed += remove_files([target])
            else:
                print(f"{target}: not found.")
        else:
            removed += remove_files(active)

    if not removed:
        print(f"{args.vars_dir}: nothing to remove.")
        return 0

    print(f"Removed {len(removed)} file(s):")
    for f in removed:
        print(f"  {f}")

    remaining_active = [
        path for path in active
        if path not in removed and os.path.exists(path)
    ]
    if args.remove_disposable and not args.remove_active and remaining_active:
        print()
        print("Active settings were left in place:")
        for path in remaining_active:
            print(f"  {path}")
        print("Remove one with: make settings-clean-force-all "
              "LOCAL_SETTINGS_FILE=<path>")
    return 0


if __name__ == '__main__':
    sys.exit(main())
