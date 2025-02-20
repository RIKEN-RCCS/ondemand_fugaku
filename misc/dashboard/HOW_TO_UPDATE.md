When updating Open OnDemand

# Check whether an active user is or not
/opt/ood/nginx_stage/sbin/nginx_stage nginx_list

mv /var/www/ood/apps/sys/dashboard/app/views/shared/_welcome.html.erb /var/www/ood/apps/sys/dashboard/app/views/shared/_welcome.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_welcome.html.erb /var/www/ood/apps/sys/dashboard/app/views/shared/

mv /var/www/ood/apps/sys/dashboard/app/views/widgets/_pinned_apps.html.erb /var/www/ood/apps/sys/dashboard/app/views/widgets/_pinned_apps.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_pinned_apps.html.erb /var/www/ood/apps/sys/dashboard/app/views/widgets/

cd /var/www/ood/apps/sys
rm -rf bc_desktop.bak myjobs.bak
mv bc_desktop bc_desktop.bak
mv myjobs myjobs.bak

The manifest.yml in files activejobs shell are changed as following.
---
category: Passenger Apps
tile:
  sub_caption: |
---

Set the timeout time to about 30 seconds.
/opt/ood/ondemand/root/usr/share/gems/[VER]/ondemand/[VER]/gems/ood_core-[VER]/lib/ood_core/batch_connect/templates/vnc.rb
