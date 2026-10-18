# Common

```sh
cd /var/www/ood/apps/sys
for app in bc_desktop projects system-status myjobs module-browser; do
  rm -rf "${app}.bak"
  mv "${app}" "${app}.bak"
done

for app in shell activejobs files; do
  rm -f "${app}/manifest.yml.bak"
  cp "${app}/manifest.yml" "${app}/manifest.yml.bak"
  cat >> "${app}/manifest.yml" <<'EOF'

tile:
  sub_caption: |
EOF
  sed -i "s/^category:.*/category: Passenger Apps/" "${app}/manifest.yml"
done

rm -f /var/www/ood/apps/sys/dashboard/app/views/shared/_welcome.html.erb.bak
mv /var/www/ood/apps/sys/dashboard/app/views/shared/_welcome.html.erb /var/www/ood/apps/sys/dashboard/app/views/shared/_welcome.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_welcome.html.erb /var/www/ood/apps/sys/dashboard/app/views/shared/

rm -f /var/www/ood/apps/sys/dashboard/app/views/layouts/_footer.html.erb.bak
mv /var/www/ood/apps/sys/dashboard/app/views/layouts/_footer.html.erb /var/www/ood/apps/sys/dashboard/app/views/layouts/_footer.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_footer.html.erb /var/www/ood/apps/sys/dashboard/app/views/layouts/

rm -f /var/www/ood/apps/sys/dashboard/app/views/widgets/_pinned_apps.html.erb.bak
mv /var/www/ood/apps/sys/dashboard/app/views/widgets/_pinned_apps.html.erb /var/www/ood/apps/sys/dashboard/app/views/widgets/_pinned_apps.html.erb.bak
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/dashboard/_pinned_apps.html.erb /var/www/ood/apps/sys/dashboard/app/views/widgets/
```

# Initial Installation

```sh
ln -s /var/www/ood/apps/sys/ondemand_fugaku/misc/global_bc_items.yml.erb /etc/ood/config/ondemand.d/
```
