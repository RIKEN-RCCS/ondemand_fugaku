# Check whether an active user is or not
/opt/ood/nginx_stage/sbin/nginx_stage nginx_list

mv /var/www/ood/apps/sys/dashboard/app/views/shared/_welcome.html.erb /var/www/ood/apps/sys/dashboard/app/views/shared/_welcome.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_welcome.html.erb /var/www/ood/apps/sys/dashboard/app/views/shared/

mv /var/www/ood/apps/sys/dashboard/app/views/widgets/_pinned_apps.html.erb /var/www/ood/apps/sys/dashboard/app/views/widgets/_pinned_apps.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_pinned_apps.html.erb /var/www/ood/apps/sys/dashboard/app/views/widgets/

mv /var/www/ood/apps/sys/dashboard/app/views/layouts/_footer.html.erb /var/www/ood/apps/sys/dashboard/app/views/layouts/_footer.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_footer.html.erb /var/www/ood/apps/sys/dashboard/app/views/layouts/

ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/global_bc_items.yml.erb /etc/ood/config/ondemand.d/

cd /var/www/ood/apps/sys
rm -rf bc_desktop.bak myjobs.bak system-status.bak
mv bc_desktop bc_desktop.bak
mv myjobs myjobs.bak
mv system-status system-status.bak

The manifest.yml in files activejobs shell are changed as following.
---
category: Passenger Apps
tile:
  sub_caption: |
---

