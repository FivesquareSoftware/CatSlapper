<?php 
#$node = $argv[3];
#$sub_node = $argv[5];
#$sub_sub_node = $argv[7];
?>
    <div id="leftNav">
<?php   if($node == "1") { ?>
        <p>Using CatSlapper</p>
        <ul>
            <li><a href="RunningCatSlapper.html">Running CatSlapper</a></li>
            <li><a href="GettingStarted.html">Getting Started</a></li>
            <li><a href="InstallingTomcat.html">Installing a Tomcat Instance</a></li>
            <li><a href="UsingDefaultEnvironment.html">Using the Default Environment</a></li>
            <li><a href="ManagingTomcatConfigurations.html">Managing Tomcat Configurations</a></li>
            <li><a href="ConfiguringMultipleTomcatInstances.html">Configuring Multiple Tomcat Instances</a></li>
            <li><a href="ControllingTomcat.html">Controlling Tomcat Instances</a></li>
            <li>
                <a href="ManagingTomcatComponents.html">Managing Tomcat Components</a>
    <?php   if($sub_node == "8" && isset($sub_sub_node)) { ?>
                <ul>
                <li><a href="AboutTheComponentsDisplay.html">The "Components" View Display</a></li>
                <li><a href="InitiatingManagerCommunication.html">Initiating Manager Communication</a></li>
                <li><a href="DetailedComponentInfo.html">Getting Detailed Component Information</a></li>
                <li><a href="ControllingComponents.html">Controlling Components</a></li>
                <li><a href="DeployingApplications.html">Deploying Applications</a></li>
                </ul>
    <?php   } ?>
            </li>
            <!--<li><a href="UsingStartupItems.html">Launching Tomcat Instances at Startup</a></li> -->
            <li><a href="UsingLaunchd.html">Launching Tomcat Instances at Startup or Login</a></li>
            <li><a href="RunningPrivileged.html">Running Tomcat as the Privileged User</a></li>
            <li><a href="GettingMoreInformation.html">Learning More About Tomcat</a></li>
        </ul>
<?php   } else { ?>
        <p><a href="RunningCatSlapper.html">Using CatSlapper</a></p>
<?php   } ?>
<?php   if($node == "2") { ?>
        <p>Troubleshooting</p>
        <ul>
            <li><a href="TomcatWontStart.html">Tomcat Won't Start</a></li>
        </ul>
<?php   } else { ?>
        <p><a href="TomcatWontStart.html">Troubleshooting</a></p>
<?php   } ?>
<?php   if($node == "3") { ?>
        <p>FAQs</p>
<!-- 
        <ul>
            <li><a href="QuestionOne.html">A Question</a></li>
        </ul>
 -->
<?php   } else { ?>
        <p><a href="Faqs.html">FAQs</a></p>
<?php   } ?>

    </div>
