/* Copyright 2018 elementary LLC (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, Inc.,; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

public class Marlin.UndoAction {
    [CCode (prefix="MARLIN_UNDO_")]
    public enum Type {
        COPY,
        DUPLICATE,
        MOVE,
        RENAME,
        CREATEEMPTYFILE,
        CREATEFILEFROMTEMPLATE,
        CREATEFOLDER,
        MOVETOTRASH,
        CREATELINK,
        DELETE,
        RESTOREFROMTRASH,
        SETPERMISSIONS,
        RECURSIVESETPERMISSIONS,
        CHANGEOWNER,
        CHANGEGROUP
    }

    private Marlin.UndoAction.Type kind;
    private uint count;

    /* Copy / Move stuff */
    private GLib.File? src_dir;
    private GLib.File? dest_dir;
    private GLib.List<string> sources;               /* Relative to src_dir */
    private GLib.List<string> destinations;          /* Relative to dest_dir */

    /* Cached labels/descriptions */
    private string? undo_label;
    private string? undo_description;
    private string? redo_label;
    private string? redo_description;

    /* Create new file/folder stuff/set permissions */
    private string? template;
    private string? target_uri;

    /* Rename stuff */
    public string? old_uri;
    public string? new_uri;

    /* Trash stuff */
    private GLib.HashTable<string, uint64> trashed;

    /* Recursive change permissions stuff */
    private GLib.HashTable<string, uint32> original_permissions;
    private uint32 dir_mask;
    private uint32 dir_permissions;
    private uint32 file_mask;
    private uint32 file_permissions;

    /* Single file change permissions stuff */
    private uint32 current_permissions;
    private uint32 new_permissions;

    /* Group */
    private string? original_group_name_or_id;
    private string? new_group_name_or_id;

    /* Owner */
    private string? original_user_name_or_id;
    private string? new_user_name_or_id;

    public UndoActionData (Marlin.UndoAction.Type kind, uint items_count) {
        this.type = type;
        count = items_count;

        if (kind == Marlin.UndoAction.Type.MOVETOTRASH) {
            trashed = GLib.HashTable<string, uint64> (str_hash, str_equal);
        }
    }

    private unowned string get_first_target_short_name () {
        return destinations.first ().data;
    }

    private static string get_uri_parent_path (string uri) {
        var file = GLib.File.new_for_uri (uri);
        return file.get_parent ().get_path ();
    }

    public unowned string get_undo_label () {
        if (undo_label == null) {
            switch (kind) {
                case Marlin.UndoAction.Type.COPY:
                    undo_label = ngettext ("_Undo copy of %d item",
                                           "_Undo copy of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.DUPLICATE:
                    undo_label = ngettext ("_Undo duplicate of %d item",
                                           "_Undo duplicate of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.MOVE:
                    undo_label = ngettext ("_Undo move of %d item",
                                           "_Undo move of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.RENAME:
                    undo_label = ngettext ("_Undo rename of %d item",
                                           "_Undo rename of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CREATEEMPTYFILE:
                    undo_label = _("_Undo creation of an empty file");
                    break;
                case Marlin.UndoAction.Type.CREATEFILEFROMTEMPLATE:
                    undo_label = _("_Undo creation of a file from template");
                    break;
                case Marlin.UndoAction.Type.CREATEFOLDER:
                    undo_label = ngettext ("_Undo creation of %d folder",
                                           "_Undo creation of %d folders", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.MOVETOTRASH:
                    undo_label = ngettext ("_Undo move to trash of %d item",
                                           "_Undo move to trash of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.RESTOREFROMTRASH:
                    undo_label = ngettext ("_Undo restore from trash of %d item",
                                           "_Undo restore from trash of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CREATELINK:
                    undo_label = ngettext ("_Undo create link to %d item",
                                           "_Undo create link to %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.DELETE:
                    undo_label = ngettext ("_Undo delete of %d item",
                                           "_Undo delete of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.RECURSIVESETPERMISSIONS:
                    undo_label = ngettext ("Undo recursive change permissions of %d item",
                                           "Undo recursive change permissions of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.SETPERMISSIONS:
                    undo_label = ngettext ("Undo change permissions of %d item",
                                           "Undo change permissions of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CHANGEGROUP:
                    undo_label = ngettext ("Undo change group of %d item",
                                           "Undo change group of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CHANGEOWNER:
                    undo_label = ngettext ("Undo change owner of %d item",
                                           "Undo change owner of %d items", count).printf (count);
                    break;
            }
        }

        return undo_label;
    }

    public string get_undo_description () {
        if (undo_description == null) {
            switch (kind) {
                case Marlin.UndoAction.Type.COPY:
                    if (count > 1) {
                        undo_description = ngettext ("Delete %d copied item",
                                                     "Delete %d copied items", count).printf (count);
                    } else {
                        undo_description = _("Delete '%s'").printf (get_first_target_short_name ());
                    }

                    break;
                case Marlin.UndoAction.Type.DUPLICATE:
                    if (count > 1) {
                        undo_description = ngettext ("Delete %d duplicated item",
                                                     "Delete %d duplicated items", count).printf (count);
                    } else {
                        undo_description = _("Delete '%s'").printf (get_first_target_short_name ());
                    }

                    break;
                case Marlin.UndoAction.Type.MOVE:
                    if (count > 1) {
                        undo_description = ngettext ("Move '%d' item back to '%s'",
                                                     "Move '%d' items back to '%s'", count).printf (count, src_dir.get_path ());
                    } else {
                        undo_description = _("Move '%s' back to '%s'").printf (get_first_target_short_name (), src_dir.get_path ());
                    }

                    break;
                case Marlin.UndoAction.Type.RENAME:
                    var from_name = GLib.Path.get_basename (new_uri);
                    var to_name = GLib.Path.get_basename (old_uri);
                    undo_description = _("Rename '%s' as '%s'").printf (from_name, to_name);
                    break;
                case Marlin.UndoAction.Type.CREATEEMPTYFILE:
                case Marlin.UndoAction.Type.CREATEFILEFROMTEMPLATE:
                case Marlin.UndoAction.Type.CREATEFOLDER:
                    undo_description = _("Delete '%s'").printf (GLib.Path.get_basename (target_uri));
                    break;
                case Marlin.UndoAction.Type.MOVETOTRASH:
                    var trashed_size = trashed.size ();
                    if (trashed_size > 1) {
                        undo_description = ngettext ("Restore %d item from trash",
                                                     "Restore %d items from trash", trashed_size).printf (trashed_size);
                    } else {
                        unowned string first_uri = trashed.first ().data;
                        undo_description = _("Restore '%s' to '%s'").printf (GLib.Path.get_basename (first_uri), get_uri_parent_path (first_uri));
                    }

                    break;
                case Marlin.UndoAction.Type.RESTOREFROMTRASH:
                    if (count > 1) {
                        undo_description = ngettext ("Move '%d' item back to trash",
                                                     "Move '%d' items back to trash", count).printf (count);
                    } else {
                        undo_description = _("Move '%s' back to trash").printf (get_first_target_short_name ());
                    }

                    break;
                case Marlin.UndoAction.Type.CREATELINK:
                    if (count > 1) {
                        undo_description = ngettext ("Delete links to %d item",
                                                     "Delete links to %d items", count).printf (count);
                    } else {
                        undo_description = _("Delete link to '%s'").printf (get_first_target_short_name ());
                    }

                    break;
                case Marlin.UndoAction.Type.RECURSIVESETPERMISSIONS:
                    undo_description = _("Restore original permissions of items enclosed in '%s'").printf (dest_dir.get_path ());
                    break;
                case Marlin.UndoAction.Type.SETPERMISSIONS:
                    undo_description = _("Restore original permissions of '%s'").printf (GLib.Path.get_basename (target_uri));
                    break;
                case Marlin.UndoAction.Type.CHANGEGROUP:
                    undo_description = _("Restore group of '%s' to '%s'").printf (GLib.Path.get_basename (target_uri), original_group_name_or_id);
                    break;
                case Marlin.UndoAction.Type.CHANGEOWNER:
                    undo_description = _("Restore owner of '%s' to '%s'").printf (GLib.Path.get_basename (target_uri), original_user_name_or_id);
                    break;
                case Marlin.UndoAction.Type.DELETE:
                    break;
            }
        }

        return undo_description;
    }

    public string get_redo_label () {
        if (redo_label == null) {
            switch (kind) {
                case Marlin.UndoAction.Type.COPY:
                    redo_label = ngettext ("_Redo copy of %d item",
                                           "_Redo copy of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.DUPLICATE:
                    redo_label = ngettext ("_Redo duplicate of %d item",
                                           "_Redo duplicate of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.MOVE:
                    redo_label = ngettext ("_Redo move of %d item",
                                           "_Redo move of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.RENAME:
                    redo_label = ngettext ("_Redo rename of %d item",
                                           "_Redo rename of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CREATEEMPTYFILE:
                    redo_label = _("_Redo creation of an empty file");
                    break;
                case Marlin.UndoAction.Type.CREATEFILEFROMTEMPLATE:
                    redo_label = _("_Redo creation of a file from template");
                    break;
                case Marlin.UndoAction.Type.CREATEFOLDER:
                    redo_label = ngettext ("_Redo creation of %d folder",
                                           "_Redo creation of %d folders", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.MOVETOTRASH:
                    redo_label = ngettext ("_Redo move to trash of %d item",
                                           "_Redo move to trash of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.RESTOREFROMTRASH:
                    redo_label = ngettext ("_Redo restore from trash of %d item",
                                           "_Redo restore from trash of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CREATELINK:
                    redo_label = ngettext ("_Redo create link to %d item",
                                           "_Redo create link to %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.DELETE:
                    redo_label = ngettext ("_Redo delete of %d item",
                                           "_Redo delete of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.RECURSIVESETPERMISSIONS:
                    redo_label = ngettext ("Redo recursive change permissions of %d item",
                                           "Redo recursive change permissions of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.SETPERMISSIONS:
                    redo_label = ngettext ("Redo change permissions of %d item",
                                           "Redo change permissions of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CHANGEGROUP:
                    redo_label = ngettext ("Redo change group of %d item",
                                           "Redo change group of %d items", count).printf (count);
                    break;
                case Marlin.UndoAction.Type.CHANGEOWNER:
                    redo_label = ngettext ("Redo change owner of %d item",
                                           "Redo change owner of %d items", count).printf (count);
                    break;
            }
        }

        return redo_label;
    }

    public string get_redo_description () {
        if (redo_description == null) {
            switch (kind) {
                case Marlin.UndoAction.Type.COPY:
                    var destination = dest_dir.get_path ();
                    if (count > 1) {
                        redo_description = ngettext ("Copy %d item to '%s'",
                                                     "Copy %d items to '%s'", count).printf (count, destination);
                    } else {
                        redo_description = _("Copy '%s' to '%s'").printf (get_first_target_short_name (), destination);
                    }

                    break;
                case Marlin.UndoAction.Type.DUPLICATE:
                    var destination = dest_dir.get_path ();
                    if (count > 1) {
                        redo_description = ngettext ("Duplicate of %d item in '%s'",
                                                     "Duplicate of %d items in '%s'", count).printf (count, destination);
                    } else {
                        redo_description = _("Duplicate of '%s' in '%s'").printf (get_first_target_short_name (), destination);
                    }

                    break;
                case Marlin.UndoAction.Type.MOVE:
                    var destination = dest_dir.get_path ();
                    if (count > 1) {
                        redo_description = ngettext ("Move %d item to '%s'",
                                                     "Move %d items to '%s'", count).printf (count, destination);
                    } else {
                        redo_description = _("Move '%s' to '%s'").printf (get_first_target_short_name (), destination);
                    }

                    break;
                case Marlin.UndoAction.Type.RENAME:
                    var from_name = GLib.Path.get_basename (old_uri);
                    var to_name = GLib.Path.get_basename (new_uri);
                    redo_description = _("Rename '%s' as '%s'").printf (from_name, to_name);
                    break;
                case Marlin.UndoAction.Type.CREATEEMPTYFILE:
                    redo_description = _("Create an empty file '%s'").printf (GLib.Path.get_basename (target_uri));
                    break;
                case Marlin.UndoAction.Type.CREATEFILEFROMTEMPLATE:
                    redo_description = _("Create new file '%s' from template").printf (GLib.Path.get_basename (target_uri));
                    break;
                case Marlin.UndoAction.Type.CREATEFOLDER:
                    redo_description = _("Create a new folder '%s'").printf (GLib.Path.get_basename (target_uri));
                    break;
                case Marlin.UndoAction.Type.MOVETOTRASH:
                    var trashed_size = trashed.size ();
                    if (trashed_size > 1) {
                        redo_description = ngettext ("Move %d item to trash",
                                                     "Move %d items to trash", trashed_size).printf (trashed_size);
                    } else {
                        unowned string first_uri = trashed.first ().data;
                        redo_description = _("Move '%s' to trash").printf (GLib.Path.get_basename (first_uri));
                    }

                    break;
                case Marlin.UndoAction.Type.RESTOREFROMTRASH:
                    if (count > 1) {
                        redo_description = ngettext ("Restore %d item from trash",
                                                     "Restore %d items from trash", count).printf (count);
                    } else {
                        redo_description = _("Restore '%s' from trash").printf (get_first_target_short_name ());
                    }

                    break;
                case Marlin.UndoAction.Type.CREATELINK:
                    if (count > 1) {
                        redo_description = ngettext ("Create links to %d item",
                                                     "Create links to %d items", count).printf (count);
                    } else {
                        redo_description = _("Create link to '%s'").printf (get_first_target_short_name ());
                    }

                    break;
                case Marlin.UndoAction.Type.RECURSIVESETPERMISSIONS:
                    redo_description = _("Set permissions of items enclosed in '%s'").printf (dest_dir.get_path ());
                    break;
                case Marlin.UndoAction.Type.SETPERMISSIONS:
                    redo_description = _("Set permissions of '%s'").printf (GLib.Path.get_basename (target_uri));
                    break;
                case Marlin.UndoAction.Type.CHANGEGROUP:
                    redo_description = _("Set group of '%s' to '%s'").printf (GLib.Path.get_basename (target_uri), new_group_name_or_id);
                    break;
                case Marlin.UndoAction.Type.CHANGEOWNER:
                    redo_description = _("Set owner of '%s' to '%s'").printf (GLib.Path.get_basename (target_uri), new_user_name_or_id);
                    break;
                case Marlin.UndoAction.Type.DELETE:
                    break;
            }
        }

        return redo_description;
    }
}
