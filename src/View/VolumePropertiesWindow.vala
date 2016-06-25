/*
* Copyright (c) 2011 Marlin Developers (http://launchpad.net/marlin)
* Copyright (c) 2015-2016 elementary LLC (http://launchpad.net/pantheon-files)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 59 Temple Place - Suite 330,
* Boston, MA 02111-1307, USA.
*
* Authored by: ammonkey <am.monkeyd@gmail.com>
*/

public class Marlin.View.VolumePropertiesWindow : Marlin.View.AbstractPropertiesDialog {

    public VolumePropertiesWindow (GLib.Mount? mount, Gtk.Window parent) {
        base (_("Disk Properties"), parent);

        GLib.File mount_root;
        string mount_name;
        GLib.Icon mount_icon;

        /* We might reach this point with mount being null, this happens when
         * the user wants to see the properties for the 'File System' entry in
         * the sidebar. GVfs is kind enough to not have a Mount entry for the
         * root filesystem, so we try our best to gather enough data. */
        if (mount != null) {
            mount_root = mount.get_root ();
            mount_name = mount.get_name ();
            mount_icon = mount.get_icon ();
        } else {
            mount_root = GLib.File.new_for_uri ("file:///");
            mount_name = _("File System");
            mount_icon = new ThemedIcon.with_default_fallbacks (Marlin.ICON_FILESYSTEM);
        }

        GLib.FileInfo info = null;

        try {
            info = mount_root.query_filesystem_info ("filesystem::*");
        } catch (Error e) {
            warning ("error: %s", e.message);
        }

        /* Build the header box */
        var file_icon = new Gtk.Image ();
        file_icon.set_from_gicon (mount_icon, Gtk.IconSize.DIALOG);

        if (file_icon != null) {
            var emblems_list = new GLib.List<string> ();

            /* Overlay the 'readonly' emblem to tell the user the disk is
             * mounted as RO */
            if (info != null &&
                info.has_attribute (FileAttribute.FILESYSTEM_READONLY) &&
                info.get_attribute_boolean (FileAttribute.FILESYSTEM_READONLY)) {
                emblems_list.append ("emblem-readonly");
            }

            overlay_emblems (file_icon, emblems_list);
        }

        header_title = new Gtk.Label (mount_name);
        header_title.halign = Gtk.Align.START;
        create_header_title ();

        int n = 1;

        var key_label = new Gtk.Label (_("Location:"));
        key_label.halign = Gtk.Align.END;

        var value_label = new Gtk.Label ("<a href=\"" + Markup.escape_text (mount_root.get_uri ()) + "\">" + Markup.escape_text (mount_root.get_parse_name ()) + "</a>");
        create_info_line (key_label, value_label, info_grid, ref n);

        if (info != null && info.has_attribute (FileAttribute.FILESYSTEM_TYPE)) {
            key_label = new Gtk.Label (_("Format:"));
            key_label.halign = Gtk.Align.END;

            value_label = new Gtk.Label (info.get_attribute_string (GLib.FileAttribute.FILESYSTEM_TYPE));
            create_info_line (key_label, value_label, info_grid, ref n);
        }

        create_storage_bar (info, ref n);

        show_all ();
        present ();
    }
}