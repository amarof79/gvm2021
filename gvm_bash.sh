#!/bin/bash
config_id="daba56c8-73ec-11df-a475-002264764cea"        #config id: full and fast
format_id="c402cc3e-b531-11e1-9163-406186ea4fc5"        #format id: pdf format
targets=${1}                                            #ip targets
IFS=","                                                 #separates input parameters by comma
username="admin"
password="admin"
user="admin"

read -ra targetArray <<< targets                        #puts input parameters in dynamic array

for i in ${targets}; do                                 #for loop for input

        #creates target with ip name
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --xml="<create_target> <name> test_${i} </name> <hosts>${i}</hosts> <port_list id='33d0cd82-57c6-11e1-8ed1-406186ea4fc5'></port_list></create_target>"
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --pretty --xml="<get_targets/>" | grep -B 4 "test_${i}" | grep "target id" > target_id.txt
        sed -i 's/<target id="//g' target_id.txt
        sed -i 's/">//g' target_id.txt
        target_id=$(cat target_id.txt | xargs)

        #creating task to scan ip
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --xml="<create_task> <name>Test_Scan_${i}</name> <comment> Fast scan on localhost </comment> <config id='${config_id}'/> <target id='${target_id}'/> </create_task>"
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --pretty --xml="<get_tasks/>" | grep -B 4 "Test_Scan_${i}" | grep "task id" > task_id.txt
        sed -i 's/<task id="//g' task_id.txt
        sed -i 's/">//g' task_id.txt
        task_id=$(cat task_id.txt | xargs)

        #begins scanning ip
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --xml="<start_task task_id='${task_id}'/>"

        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --pretty --xml="<get_tasks task_id='${task_id}'/>" | grep -m 1 "<status>" > scan_progress.txt

        sed -i "s/<status>//g" scan_progress.txt
        sed -i "s/<\/status>//g" scan_progress.txt
        scan_progress=$(cat scan_progress.txt | xargs)

        while [ ${scan_progress} != "Done" ]
        do
                runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --pretty --xml="<get_tasks task_id='${task_id}'/>" | grep -m 1 "<status>" > scan_progress.txt
                sed -i "s/<status>//g" scan_progress.txt
                sed -i "s/<\/status>//g" scan_progress.txt
                scan_progress=$(cat scan_progress.txt | xargs)
                echo ${scan_progress}
                sleep 10

        done

        #grabs report id
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --pretty --xml="<get_tasks task_id='${task_id}'/>" | grep "report id" > report_id.txt
        sed -i 's/<report id="//g' report_id.txt
        sed -i 's/">//g' report_id.txt
        report_id=$(cat report_id.txt | xargs)

        #outputs report in pdf format, in a file
	mkdir temp ; cd temp
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --pretty --xml="<get_reports report_id='${report_id}' format_id='${format_id}' details='1' ignore-pagination='1'/>" | grep -B 50 -e "</report>" | grep -o -e "</report_format>.*" > base64Encode.txt

        sed -i "s/=<\/report>//g" base64Encode.txt
        sed -i "s/<\/report_format>//g" base64Encode.txt
	sed -i "s/<\/report>//g" base64Encode.txt
        base64 -d base64Encode.txt > pdfFile_${i}.pdf 

        #removes task and task id file
	cd ..
        runuser -u ${user} -- gvm-cli --gmp-username ${username} --gmp-password ${password} socket --xml="<delete_task task_id='${task_id}'/>"
        rm -rf task_id.txt report_id.txt scan_progress.txt target_id.txt
done
