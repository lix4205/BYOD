# BYOD (Bring Your Own Distribution)
Ce script est destin&eacute; &agrave; installer une distribution ArchLinux ou debian avec un environnement de bureau minimal ( Web, Multimedia ).
<br />Il a &eacute;t&eacute; conçu afin d'installer une distribution depuis un syst&egrave;me d&eacute;j&agrave; op&eacute;rationnel, type LiveCD.<br />Fonctionne sur ArchLinux, Debian et ses dérivées, et probablement la plupart des distributions...
<br />On peut aussi placer un script du nom de l'utilisateur dans "anarchi/files/custom.d" afin de personnaliser votre environnement post-installation.
<br />Ce script peut aussi effectuer une installation sans disque destin&eacute;e &agrave; être boot&eacute;e en r&eacute;seau ( 
param&egrave;tre "-n nfsroot" )...
# Fonctionnement
ATTENTION : On part du principe que la partition de notre future installation est format&eacute;e et mont&eacute;e sur le syst&egrave;me hôte ! ( 
Hormis pour une installation sans disque... )<br />
Il s'agit ensuite de lancer le script avec<br />
<code># /path/to/the/script/launchinstall.sh /path/to/install</code><br />
Un seul param&egrave;tre est requis, le dossier dans lequel installer.<br />
<strong>Remarque: </strong>Dans cet exemple, aucun chargeur de d&eacute;marrage ne sera install&eacute; !<br />
Si aucun param&egrave;tre n'a &eacute;t&eacute; pass&eacute;, une s&eacute;rie de question concernant le mat&eacute;riel et la personnalisation du 
syst&egrave;me seront pos&eacute;es. <br />
Toutefois vous pouvez passez les param&egrave;tres directement, voici une rapide description :
<ul class="opts_list">
    <li>Le premier param&egrave;tre &agrave; passer est la LOCALE (UTF-8 uniquement) utilis&eacute;e par le syst&egrave;me donc quelque chose du type : <br /><code># /path/to/the/script/launchinstall.sh en_GB /path/to/install </code></li>
    <li>Tout comme pacstrap ,on peut ajouter des logiciels particulier en ajoutant les noms des paquets &agrave; la fin de la ligne de commande.<br />Par exemple pour GIMP et STEAM<br /><code># /path/to/the/script/launchinstall.sh en_GB /path/to/install gimp steam</code></li>
    <li>Tout les autres param&egrave;tre peuvent être pass&eacute; de mani&egrave;re al&eacute;atoire
    <ul class="opts_list">
        <!-- Pacstrap options -->
        <li><strong>-C </strong><span>&lt;config&gt;</span><br />
        Use an alternate config file for pacman</li>
        <li><strong>-d</strong><br />
        Allow installation to a non-mountpoint directory</li>
        <li><strong>-G</strong><br />
        Avoid copying the host's pacman keyring to the target</li>
        <li><strong>-i</strong><br />
        Avoid auto-confirmation of package selections</li>
        <li><strong>-M</strong><br />
        Avoid copying the host's mirrorlist to the target<br /><br /></li>
        <!-- Common options-->
        <li><strong>-a </strong><span>&lt;arch&gt;</span><br />
        Architecture du processeur (x64/i686)</li>
        <li><strong>-n </strong><span>&lt;net_pref&gt;</span><br />
        Au choix: dhcpcd/dhcpcd@&lt;inet_addr&gt;,nm/networmanager<br>
        Utilisation de NetworkManager ou dhcpcd sur toutes les interfaces ou avec l'interface &lt;inet_addr&gt;</li>
        <li><strong>-g </strong><span>&lt;gpu_drv&gt;</span><br />
        Pilote carte graphique parmi intel,nouveau,radeon/ati,virtualbox/vb,nvidia/nvidia304/nvidia340,all ( all pour tout les pilotes)</li>
        <li><strong>-e </strong><span>&lt;desk_env&gt;</span><br />
        Environnement de bureau parmi plasma,lxqt,xfce,lxde,mate,gnome</li>
        <li><strong>-h </strong><span>&lt;hostname&gt;</span><br />
        Nom de la machine</li>
        <li><strong>-u </strong><span>&lt;username&gt;</span><br />
        Login utilisateur<br /><br /></li>			
        <!-- Langage/Location options-->
        <li><strong>-k </strong><span>&lt;kbd_conf&gt;</span><br />
        Disposition du clavier en console</li>
        <li><strong>-K </strong><span>&lt;xkbd_conf&gt;</span><br />
        Disposition du clavier sous X</li>
        <li><strong>-z </strong><span>&lt;Zone/SousZone&gt;</span><br />
        Fuseau horaire &agrave; suivre<br /><br /></li>			
        <!-- Advanced -->
        <li><strong>-l </strong><span>&lt;/dev/sdX&gt;</span><br />
        Installe le chargeur de d&eacute;marrage grub sur le p&eacute;ripherique /dev/sdX.</li>
        <li><strong> -c </strong><span>&lt;cache_paquets&gt;</span><br />
        Utilisation des paquets contenu dans le dossier &lt;cache_paquets&gt;<br /><br /></li>			
        <!-- Other (Printing, Bluetooth, usefull softwares)-->
        <li><strong>-s </strong>Gestion touchpad (xf86-input-synaptics)<br />
        Disposition du clavier en console</li>
        <li><strong>-p</strong><br />
        Gestion imprimante ( cups )</li>
        <li><strong>-H</strong><br />
        Gestion imprimante HP ( cups + hplip )</li>
        <li><strong>-b</strong><br />
        Gestion du bluetooth ( bluez bluez-utils )</li>
        <li><strong>-L</strong><br />
        Installation de libreoffice</li>
        <li><strong>-T</strong><br />
        Installation de thunderbird<br /><br /></li>
        <li><strong>-t</strong><br />
        Test mode, commands are in /tmp/anarchi_command</li>
        <li><strong>-h</strong><br />
        Print this help message</li>
    </ul>
    </li>
</ul>	

# Exemple
Ce qui nous donne pour une distribution <strong>x64</strong>, avec <strong>NetworkManager</strong> pour le r&eacute;seau, <strong>intel</strong> comme driver graphique, l'environnement de bureau <strong>xfce</strong>, un utilisateur <strong>user</strong>, <strong>hostname</strong> comme nom de machine, Grub sur le disque <strong>/dev/sdf</strong>, la gestion des imprimantes avec <strong>cups</strong>, <strong>libreoffice</strong> et <strong>thunderbird</strong> ainsi que <strong>gimp</strong> et <strong>steam</strong>. Le tout en <strong>francais</strong>.<br />
Pour ArchLinux :<br />
<code># /path/to/the/script/launchinstall.sh fr_FR -K fr -k fr-latin1 -z Europe/Paris -a x64 -n nm -g intel  -e xfce -h hostname -u user -l /dev/sdf -p -TL /path/to/install gimp steam</code>
Pour Debian :<br />
<code># /path/to/the/script/launchinstall.sh debian fr_FR -K fr -k fr-latin1 -z Europe/Paris -a x64 -n nm -g intel  -e xfce -h hostname -u user -l /dev/sdf -p -TL /path/to/install gimp steam</code>
# CAUTION !
L'installation de debian présente quelques soucis au niveau de certaines dépendances entre paquets selon les versions...<br />
