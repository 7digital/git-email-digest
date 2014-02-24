#! /bin/bash

usage() {
	cat << EOF

Usage: git-digest <repo-path> <recipient> [--dry-run] [--help]

  repo-path     Path to the git repository
  recipient     Email address to send the digest to
  dry-run       Print the digest on stdout instead of sending an email
  help          Show this message

EOF
}

die() {
	echo
	echo "$@" 1>&2
	echo
	exit 1
}

if  [ "$1" = "--help" ]; then
	usage
	exit 0
fi

if [ "$#" -lt 2 ]; then
	usage
	die "Not enough arguments"
fi

REPONAME=`basename "$1"`
TEMP_FILENAME="/tmp/git-digest-${REPONAME}"
REPO_PATH="$1"
RECIPIENT="$2"
SUBJECT="Weekly Git Digest for ${REPONAME}"

rm $TEMP_FILENAME 2>&1
touch  $TEMP_FILENAME
cd $REPO_PATH
git pull > /dev/null 2>&1
echo "Commits released or pending release on master this week" >> $TEMP_FILENAME
echo "-------------------------------------------------------" >> $TEMP_FILENAME
git log --pretty='%an : %s' --after="last week" &>> $TEMP_FILENAME
echo -e "\n" >> $TEMP_FILENAME

echo "Unmerged branches" >> $TEMP_FILENAME
echo "-------------------------------------------------------" >> $TEMP_FILENAME
git branch --no-merged master -a &>> $TEMP_FILENAME
echo -e "\n" >> $TEMP_FILENAME

echo "Active branches (Top 5 by last commit date)" >> $TEMP_FILENAME
echo "-------------------------------------------------------" >> $TEMP_FILENAME
git for-each-ref --sort=-committerdate --format='%(committerdate:short) %(refname)' --count=5 refs/remotes &>> $TEMP_FILENAME
echo -e "\n" >> $TEMP_FILENAME

if [ "$3" = "--dry-run" ]; then
	echo "Would have emailed the following to: ${RECIPIENT}"
	echo
	echo "Subject: ${SUBJECT}"
	echo
	cat "${TEMP_FILENAME}"
else
	mail -s "${SUBJECT}" $RECIPIENT < $TEMP_FILENAME
fi

