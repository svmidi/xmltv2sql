#!/bin/bash
declare -a channels=(1 2 3 4 5 101 102 103 104 105 109 201 202 203 206 208 211 213 214 216 218 219 231 235 255 269 276 284 288 289 291 292 293 315 326 329 330 448 530 554 556 558 563 585 586 595 620 631 636 662 663 666 676 686 714 790 919 927 940 974 1002 1018 1071 1078 1342 1354 1356 1391 1429 1465 1552 1612 1700 1900 1968 1991 2006 100002 100010 100018 100036 100037 100038 100055 100057 100077 100078 300007 300010 300047 300048 300097 300105 300110 300124 300125 300126)
DB="database_name"

in_array () {
    local haystack=${1}[@]
    local needle=${2}
    for i in ${!haystack}; do
        if [[ ${i} == ${needle} ]]; then
            return 0
        fi
    done
    return 1
}

read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
    local ret=$?
    
    TAG_NAME=${ENTITY%% *}
    ATTRIBUTES=${ENTITY#* }
    return $ret
}

parse_dom () {
    gen=1
    if [[ $TAG_NAME = "programme" ]] ; then
        eval local $ATTRIBUTES
        start=${start%% *}
        start=`date -d"$(sed -r 's#(.{4})(.{2})(.{2})(.{2})(.{2})#\1/\2/\3 \4:\5:#' <<< "${start}")" "+%s"`
        stop="${stop%% *}"
        stop=`date -d"$(sed -r 's#(.{4})(.{2})(.{2})(.{2})(.{2})#\1/\2/\3 \4:\5:#' <<< "${stop}")" "+%s"`
        strt=$start
        str="('$start', '$stop', '$channel'"
        ch=$channel
    elif [[ $TAG_NAME = "title" ]] ; then
            str="${str}, '${CONTENT}'"
    elif [[ $TAG_NAME = "category" ]] ; then
        if [[ $CONTENT = "Развлекательные" ]] ; then
            CONTENT="${str}, '${CONTENT}'),"
            gen=1
        elif [[ $CONTENT = "Информационные" ]] ; then
            gen=2
        elif [[ $CONTENT = "Познавательные" ]] ; then
            gen=3
        elif [[ $CONTENT = "Сериал" ]] ; then
            gen=4
        elif [[ $CONTENT = "Художественный фильм" ]] ; then
            gen=5
        elif [[ $CONTENT = "Для взрослых" ]] ; then
            gen=6
        elif [[ $CONTENT = "Детям" ]] ; then
            gen=7
        elif [[ $CONTENT = "Спорт" ]] ; then
            gen=8
       else
            echo $CONTENT
        fi
        CONTENT="${str}, '${gen}'),"

        if in_array channels $ch; then
            echo $CONTENT >> sql.sql
        fi
    fi
}
#echo $1
#exit
echo "USE \`${DB}\`;TRUNCATE \`tv_program\`;INSERT INTO \`tv_program\` (\`date_from\`, \`date_to\`, \`channel_id\`, \`description\`, \`genre\`)  VALUES " > sql.sql

while read_dom; do
    parse_dom
done

LAST=`tail -n 1 sql.sql | sed 's/.$//'`
sed -i -e '$d' sql.sql
echo "${LAST};" >>sql.sql
