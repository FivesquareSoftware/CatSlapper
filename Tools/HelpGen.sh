#!/bin/bash

#echo "BUILD_STYLE=$BUILD_STYLE"
if [ "$BUILD_STYLE" = "Debug" ] ; then
    echo "Not generating help documentation"
    exit 0
fi

LOCALIZATIONS=("English.lproj")

for LOC in ${LOCALIZATIONS[@]} ; do

    RUN_DIR="${PROJECT_DIR}/Resources/Documentation/$LOC"
    SRC_DIR="${RUN_DIR}/CatSlapperHelp"
    OUT_DIR="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/$LOC/CatSlapperHelp"
    #OUT_DIR="${TARGET_TEMP_DIR}/English.lproj/CatSlapperHelp"
    
    mkdir -p "$OUT_DIR/Contents"
    
    cd $RUN_DIR
    
    FILES=`find $SRC_DIR/Contents -name '*.html'`
    
    for FILE in ${FILES[@]} ; do
        FILENAME=`basename $FILE`
        OUTFILE="$OUT_DIR/Contents/$FILENAME"
        echo "Generating help file: $OUTFILE"
        php $FILE > "$OUTFILE"
    done
    
    ditto "$SRC_DIR/images" "$OUT_DIR/images"
    cp $SRC_DIR/*.css $OUT_DIR
    cp $SRC_DIR/*.html $OUT_DIR
done