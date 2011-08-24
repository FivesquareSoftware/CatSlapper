#!/bin/bash

#echo "BUILD_STYLE=$BUILD_STYLE"
if [ "$BUILD_STYLE" = "Debug" ] ; then
    echo "Not indexing help documentation"
    exit 0
fi


DOC_DIR="$PROJECT_DIR/Resources/Documentation"
LOCALIZATIONS=("English.lproj")
BASE_OPTS="-Tokenizer 1 -IndexAnchors YES -MinTermLength 3 -ShowProgress YES -LogStyle 2" 
TIGER_OPTS="$BASE_OPTS -TigerIndexing YES -GenerateSummaries YES"
PANTHER_OPTS="$BASE_OPTS -PantherIndexing YES"

cd /Developer/Applications/Utilities/Help\ Indexer.app/Contents/MacOS
for LOC in ${LOCALIZATIONS[@]} ; do
	HELP_DIR="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/$LOC/CatSlapperHelp"
	echo -n "Indexing $HELP_DIR ..."
	./Help\ Indexer $HELP_DIR $TIGER_OPTS
	echo "ok"
done

exit 0