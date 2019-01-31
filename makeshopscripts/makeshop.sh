#!/bin/bash
#Written by Aroon Mishra
#Contact arun123ks@gmail.com
#skype : arunmishra32
#phone : +918527147193 (call, whatsup)
conf="$HOME/aroonk/makeshop/conf/$1mks.conf"
rssrv=`cat $conf | grep rssrv | cut -d "=" -f 2 `
amifile=`cat $conf | grep amifile | cut -d "=" -f 2 `
instanceiddd=`cat $conf | grep instanceiddd | cut -d "=" -f 2 `
amipref=`cat $conf | grep amipref | cut -d "=" -f 2 `
amidesc=`cat $conf | grep amidesc | cut -d "=" -f 2 `
secgrps=`cat $conf | grep secgrps | cut -d "=" -f 2 `
kyname=`cat $conf | grep kyname | cut -d "=" -f 2 `
asgname=`cat $conf | grep asgname | cut -d "=" -f 2 `
trgarn=`cat $conf | grep trgarn | cut -d "=" -f 2 `
lcpref=`cat $conf | grep lcpref | cut -d "=" -f 2 `
instpe=`cat $conf | grep instpe | cut -d "=" -f 2 `
imrole=`cat $conf | grep imrole | cut -d "=" -f 2 `
subntid=`cat $conf | grep subntid | cut -d "=" -f 2 `
dat=$(date +"%Y%m%d%H%M")
lcname=$lcpref$dat
aminame1="shopstage1"
aminame=$amipref$dat
stgfl=`cat $conf | grep stgfl | cut -d "=" -f 2 `
snapfile=`cat $conf | grep snapfile | cut -d "=" -f 2 `
echo "Checking conf file existence"

if [ -f "$conf" ]

 then 
     echo "Time: $(date) $conf found"

 else 
     echo "Time: $(date) $conf not found"
     exit 
fi


echo "Checking variables value"


if [  ! -z "$rssrv" ] ||  [ ! -z "$amifile" ] || [ ! -z "$instanceiddd" ] || [ ! -z "$aminame" ] || [ ! -z "$amidesc" ] || [ ! -z "$secgrps" ] || [ ! -z "$kyname" ] || [ ! -z "$asgname" ] \
	|| [ ! -z "$trgarn" ] || [ ! -z "$lcname" ] || [ ! -z "$aminame" ] || [ ! -z "$lcpref" ] || [ ! -z "$imrole" ] || [ ! -z "$subntid" ] || [ ! -z "$stgfl" ]  \
	   || [ ! -z "$stgfl" ] ; \
 then  
     echo "Time: $(date) all variable values found" 
 else 
     echo "Time: $(date) all varibales values are not found"
     exit
fi 



#Make shop mode on on Master server
echo "Time: $(date) enbaling shop mode on master"

ssh $rssrv "sudo  sh /opt/enbaleshopmode.sh"

  if [ $? -eq 0 ]
        then
              echo "Enbaled Shop mode"
	      echo "Will wait 300 secs to get all files updated"
	      seconds=300; date1=$((`date +%s` + $seconds));
while [ "$date1" -ge `date +%s` ]; do
  echo -ne "$(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
done

	     # sleep 600
      else 
	     echo "Unable to enbale shop mode"
	     exit
  fi	     


echo "Time: $(date) creating ami file  for preaparation server"

echo "Creating AMI for preaparation server"

touch $amifile

  if [ $? -eq 0 ]
        then
aws ec2 create-image --instance-id $instanceiddd --name "$aminame1" --description $amidesc --no-reboot  > $amifile
      if [ $? -eq 0 ]
        then
            echo "Time: $(date) ami created sucsessfuly for preapration server" 
        else 
           echo "Time: $(date) unbale to create AMI for preaparation server"
	   exit
     fi     
   else  
      echo "Time: $(date) unbale to create $amifile for preaparation server" 
      exit
 fi 


echo "Checking AMI status of preaparation server, can wait max 15 min in 1 min loop"

for ((x = 1 ; x <= 15 ; x++)); 

do	

echo "Time: $(date) waiting for 60 sec" 
seconds=60; date1=$((`date +%s` + $seconds)); 
while [ "$date1" -ge `date +%s` ]; do 
  echo -ne "$(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r"; 
done


# Check AMI status, If available then go next
      echo "Time: $(date) Checking $dat AMI status for preaparation server"  
      amiidms=`cat $amifile | grep ami | cut -d ":" -f 2 | tr -d "{ " | tr -d "} " | tr -d '" '`
      echo $amiidms 
      amistat=`aws ec2 describe-images --image-ids  $amiidms | grep "State" | cut -d ":" -f 2 | tr -d '^"' | tr -d ',' | tr -d '^ '`
      echo $amistat
      vov="available"
if [ "$amistat" = "$vov" ];
      then 
          echo "Time: $(date) $dat AMI status is available for preapration server"
	  x=15 
else
     echo "Time: $(date) $dat AMI status is not available yet for preapration server"
#     echo $x
     if [ $x = 15 ];
	   then 
		exit 
	else
            echo $x		
     fi		
fi

done


echo "Time: $(date) Going to launch preapration server" 

echo "Creating instnace id file"

touch $stgfl

echo "Launching Server"

aws ec2 run-instances --image-id $amiidms --count 1 --instance-type $instpe --key-name $kyname \
	--security-group-ids $secgrps --subnet-id $subntid > $stgfl  \

	if [ $? -eq 0 ]
                         then
               echo "instances launched seccusesfully"
       else
             echo "Error during running launching instances" 
             exit
      fi
echo "Checking luanch instance status"

 msinstid=`cat $stgfl | grep InstanceId | awk {'print $2'} | tr -d '" ' | tr -d ", "`

           if  [ ! -z "$msinstid" ];
                  
	   then 
                 echo "Got instance id" 
           else 
		echo "Unbale to get instance id of preparation server"
	        exit	
           fi

echo "Checking Launch  instance status of preaparation server, can wait max 15 min in 1 min loop"

for ((p = 1 ; p <= 25 ; p++));

do

echo "Time: $(date) waiting for 30 sec" 
seconds=30; date11=$((`date +%s` + $seconds));
while [ "$date11" -ge `date +%s` ]; do
  echo -ne "$(date -u --date @$(($date11 - `date +%s` )) +%H:%M:%S)\r";
done

instos="running"
instsc=`aws ec2 describe-instance-status --instance-id $msinstid | grep -A 3 InstanceState | grep Name | awk {'print $2'} | tr -d '" '`

 if [ "$instos" = "$instsc"  ];
     then
	  echo "Instancse is running we will create AMI"  
	  sleep 180 
	  p=25   
     else 
	 echo "Instance status is not running yet"   
	   if [ $p = 25 ];
              then
               exit
              else
                      echo $p
 	      fi
      fi
  
done 

##Going to creating final AMI for shop server


aws ec2 create-image --instance-id $msinstid --name "$aminame" --description $amidesc --no-reboot  > $amifile
      if [ $? -eq 0 ]
        then
            echo "Time: $(date) final shop ami created sucsessfuly" 
        else
           echo "Time: $(date) unbale to create final shop AMI"
           exit
     fi





echo "Checking AMI status, can wait max 15 min in 1 min loop"

for ((n = 1 ; n <= 15 ; n++));

do

echo "Time: $(date) waiting for 60 sec" 
seconds=60; date12=$((`date +%s` + $seconds));
while [ "$date12" -ge `date +%s` ]; do
  echo -ne "$(date -u --date @$(($date12 - `date +%s` )) +%H:%M:%S)\r";
done


# Check AMI status, If available then go next
      echo "Time: $(date) Checking $dat AMI status"  
      amiid=`cat $amifile | grep ami | cut -d ":" -f 2 | tr -d "{ " | tr -d "} " | tr -d '" '`
      echo $amiid 
      amistat=`aws ec2 describe-images --image-ids  $amiid | grep "State" | cut -d ":" -f 2 | tr -d '^"' | tr -d ',' | tr -d '^ '`
      echo $amistat
      vov="available"
if [ "$amistat" = "$vov" ];
      then
          echo "Time: $(date) $dat AMI status is available"
          n=15
else
     echo "Time: $(date) $dat AMI status is not available yet"
#     echo $x
     if [ $n = 15 ];
           then
                exit
        else
            echo $n             
     fi
fi

done








echo "Time: $(date) creating launch configuration" 
          # Create Launch Configuration with new AMI
aws autoscaling create-launch-configuration --launch-configuration-name $lcname --key-name $kyname --image-id $amiid \
                                            --security-groups $secgrps --instance-type $instpe --iam-instance-profile $imrole \
	                                    
                    if [ $? -eq 0 ]
                         then
                         echo "Time: $(date) Launch configuration created successfuly"
# Update Autoscale Group to use new Launch Configuration
                         echo "Time: $(date) updating Launch configuration in ASG"
         aws autoscaling update-auto-scaling-group --auto-scaling-group-name $asgname --launch-configuration-name $lcname
                        if [ $? -eq 0 ]
                         then 
                          echo "Time: $(date) Launch configuration updated in ASG"
                         else
		          echo "Time: $(date) Unbale to update LC in ASG, exiting"
	                  exit
	                fi 		  
                    else
                     echo "Time: $(date) Unbale to create Launch configuration"  
                    exit
                  fi


echo "Going to launch new Instances from New LC"
  cdic=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name  $asgname | grep InstanceId | wc -l`
        if [ $? -eq 0 ]
                        then
                              echo $cdic
                              # nx=2
                              ndic=$((2*cdic))
                              echo $ndic
                                 aws autoscaling set-desired-capacity --auto-scaling-group-name $asgname --desired-capacity $ndic
                                 if [ $? -eq 0 ]
                                   then
                                       echo "Set desire instance size $ndic to ASG $asgname"
                                   else
                                       echo "Unable to set desire instance count"
			         fi  
			 else    	 
      		              echo "Unbale to get auto scale instance count"
	                      exit		      
        fi

      
# Spin New instances
echo "Let new instances launch and come in service, will wait till 450 secs"
for ((y = 1 ; y <= 15 ; y++));
do
echo "Time: $(date) waiting for 30 sec" 
seconds=30; date1=$((`date +%s` + $seconds));
while [ "$date1" -ge `date +%s` ]; do
echo -ne "$(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
done
     adic=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name  $asgname | grep InstanceId | wc -l`
     if [ $? -eq 0 ]
                      then
                                      if (( $adic >= $ndic ));
					      then   
                                                     echo "New instances are laucnhed"
						     y=15
                                              else
                                                    echo "New instancse are not launched yet"
	                                            if [ $y = 15 ];
                                                        then
                                                            exit
                                                    else
                                                         echo $y
                                                    fi
                                      fi
                        else    
                                    echo "Unbale to get new count of autoscale instances"
	                            exit
      fi	      

done


echo "Checking target group health status"

for ((k = 1 ; k <= 15 ; k++));
do
echo "Checking target group instances health status, will wait till 450 secs"	
echo "Time: $(date) waiting for 30 sec" 
seconds=30; date1=$((`date +%s` + $seconds));
while [ "$date1" -ge `date +%s` ]; do
  echo -ne "$(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
done


 tsrvc=`aws elbv2 describe-target-health --target-group-arn $trgarn | grep healthy | grep -v unhealthy | wc -l`
 if [ $? -eq 0 ]
       then

              if (( $tsrvc >= $ndic ));
                   then
                       echo "All new server are in healthy, let remove old instances"
     aws autoscaling set-desired-capacity --auto-scaling-group-name $asgname --desired-capacity $cdic 
                         if [ $? -eq 0 ]
                                then
                                k=15
	                else
                                echo "unbale to set desire instance count"
                        fi		 
                 else
                      echo "Still new instancse are not in service"
	              if [ $k = 15 ];
                            then
                                exit
                            else
                                echo $k
                       fi 
              fi		
        else
		   echo "Unbale to get count of healthy instances in target group"
 fi						   
   done

echo "Terminating preaparing server"

aws ec2 terminate-instances --instance-ids $msinstid

 if [ $? -eq 0 ]
          then
                echo "Preaparion server terminated"
           else 
                echo "Unable to terminate preapration server"
 fi         		

echo "Going to delete preapration server AMI"

touch $snapfile

aws ec2 describe-images --image-ids $amiidms | grep snap |  awk ' {print $2} ' | tr -d '"' | tr -d "," > $snapfile
                    echo  "Time: Following are the snapshots associated with it : `cat $snapfile`:\n "
                    if [ -s $snapfile ]
                        then
                        echo "Time: $(date) $snapfile is not empty"
                        echo  "Time: $(date) Starting the Deregister of AMI... \n"
                        #Deregistering the AMI
                        aws ec2 deregister-image --image-id $amiidms
                         if [ $? -eq 0 ]
                                 then
                                   echo "Preaparion server terminated"
                                 else
                                   echo "Unable to terminate preapration server"
                         fi


                        echo "Time: $(date) \nDeleting the associated snapshots.... \n"
                        #Deleting snapshots attached to AMI
                        for i in `cat $snapfile`;do aws ec2 delete-snapshot --snapshot-id $i ; done
	        fi    



echo "sleeping for 60 sec and then will disable shop mode on master server"
sleep 60
          echo "Time: $(date) disableing master server shop mode"
         ssh $rssrv "sudo  sh /opt/disableshopmode.sh"
                                if [ $? -eq 0 ]
                                     then
                                     echo "Time: $(date) Master server shop mode disabled"
                                else
                                      echo "Time: $(date) Master server shop mode disableing failed, pls do it manualy"
                                  fi
echo "Removing AWS CLI creadentials"

> /home/aroon/.aws/credentials


