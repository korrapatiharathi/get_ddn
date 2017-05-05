
#!/bin/sh
#integration script for DDN Logs

ddn_arrays=$(cat<<EOF
iforge-14k,10.142.160.130,10.142.160.131
sdd90,10.142.160.16,10.142.160.17
sdd91,10.142.160.18,10.142.160.19
sdd30,10.142.150.88,10.142.150.89
sdd31,10.142.150.90,10.142.150.91
sdd32,10.142.150.92,10.142.150.93
sdd33,10.142.150.94,10.142.150.95
cc-s10k,10.10.2.105,10.10.2.106
cc-s12k,10.10.2.101,10.10.2.104
EOF
)

ddn_string=""

declare -A ddn_map

for addr in $ddn_arrays;do
   OIFS="$IFS"
   IFS=' '
   read -a ipaddresses <<< "${addr}"
   IFS="$OIFS"
   for ipaddressLine in "${ipaddresses[@]}";do
       #echo $ipaddressLine
       OIFS="$IFS"
       IFS=','
       read -a ipaddressarray <<< "${ipaddressLine}"
       IFS="$OIFS"
       ddn_name=${ipaddressarray[0]}
       ipaddressarray=("${ipaddressarray[@]:1}") #removed the 1st element
       #reading and creating a dictionary of ddn and ip addresses
       ddn_map[$ddn_name]=${ipaddressarray[@]}
           ddn_string="${ddn_string} $ddn_name"
           #echo "key: "
           #echo $ddn_name
           #echo "value: "
           #echo ${ipaddressarray[@]}
   done
done

if [ $# == 0 ]
then
   # use here docs to pull data
   echo "Usage: get_ddn [-d | -l] [-n] [-s SRnumber] [DDN name]

        Options:
        -d collect diag output from the DDN system
        -l collect log (SUBsystem SUMmary) output from the DDN system (default)
        -n prints the list of known DDN systems and their addresses
        -s optional SR number to add to filename(s) (required with -d)";

else
   option=$1
   #Extracting names of DDN and displaying them when user enters "n" as an argument
   if [ $# == 1 ] && [ "$option" == "-n" ];then
               for key in ${!ddn_map[@]}; do
                   echo $key
            done
   else
                for TOKEN in $*;do
                        ddn_found=0
                        #if [ "$TOKEN" != "iforge-14k" ]; then
                        #       echo "Invalid host: $TOKEN"
                        #       continue
                        #fi
                             for key in ${!ddn_map[@]}; do
                                if [ ${key} == $TOKEN ];then
                                        #Setting flag to find valid hosts
                                        ddn_found=1
                                        dirname=`date +%Y-%m-%d-%H-%M.${TOKEN}`
                                        if [ ! -d "$dirname" ];
                                        then
                                        mkdir ./$dirname
                                 fi
                                 ddn_address=${ddn_map[${key}]}
                                 i=0
                                 today=`date +%Y-%m-%d-%H-%M`
                                        for ipaddress in $ddn_address;do
                                                echo "show sub sum" | ssh -i sfa.key -l user $ipaddress | tee ./$dirname/${today}.${key}-$i.ss
                                                echo "show sub sum all" | ssh -i sfa.key -l user ${ipaddress} | tee ./$dirname/${today}.${key}-$i.ssa
                                                echo "app show sub sum" | ssh -i sfa.key -l user ${ipaddress} | tee ./$dirname/${today}.${key}-$i.appss
                                        i=$[i + 1]
                                        done
                                        tar zcf ${today}.${key}-sub_sum.tgz ./$dirname/${today}.${key}*.ss ./$dirname/${today}.${key}*.ssa ./$dirname/${today}.${key}*.appss
                                fi
                        done
                        if [ "$ddn_found" != 1 ]; then
                                #Checking host validity
                                echo "Invalid host: $TOKEN"
                                echo "valid hosts: $ddn_string"
                        fi
                done
        fi
fi
