#!/usr/bin/env python3
"""List or remove one project's machine-local settings files.

Two tiers, deliberately not treated the same way:

  disposable  any *.local.yml.bak file, left behind by `make settings
              FORCE=1`, plus any leftover settings-reference.local.yml from
              a retired generator mode. Both regenerate or are recreated by
              `make settings`, so removing them loses nothing irreplaceable.

  active      settings.local.yml itself. This holds real, hand-built
              configuration - hosts, credentials, instance definitions -
              that took real work to create. It is gitignored on purpose, so
              git does not back it up either: removing it is not reversible.

Default action is --list: print what exists in each tier and remove nothing.
--remove-disposable deletes only the disposable tier.
--remove-active deletes the disposable tier AND settings.local.yml.
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
    active = sorted(glob.glob(os.path.join(vars_dir, 'settings.local.yml')))
    return disposable, active


def list_files(vars_dir, disposable, active):
    if not disposable and not active:
        print(f"{vars_dir}: no machine-local settings files found. Nothing to clean.")
        return

    print(f"{vars_dir}: found the following machine-local settings files.")
    if disposable:
        print("  Disposable (regenerable, safe to remove):")
        for f in disposable:
            print(f"    {f}")
    if active:
        print("  ACTIVE (your real configuration, NOT backed up by git):")
        for f in active:
            print(f"    {f}")
    print()
    if disposable:
        print("Remove only the disposable ones with: make settings-clean-force")
    if active:
        print("Also remove your active settings with: make settings-clean-force-all")
        print("That is not reversible: back up anything you cannot recreate first.")


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
                              'settings.local.yml.')
    parser.add_argument('--remove-active', action='store_true',
                         help='Delete the disposable tier AND '
                              'settings.local.yml. Not reversible.')
    args = parser.parse_args()

    disposable, active = find_files(args.vars_dir)

    if not args.remove_disposable and not args.remove_active:
        list_files(args.vars_dir, disposable, active)
        return 0

    removed = remove_files(disposable)
    if args.remove_active:
        removed += remove_files(active)

    if not removed:
        print(f"{args.vars_dir}: nothing to remove.")
        return 0

    print(f"Removed {len(removed)} file(s):")
    for f in removed:
        print(f"  {f}")

    if args.remove_disposable and not args.remove_active and active:
        print()
        print(f"Your active settings were left in place: {active[0]}")
        print("Remove that too with: make settings-clean-force-all")
    return 0


if __name__ == '__main__':
    sys.exit(main())
