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
public struct Marlin.UndoMenuData {
    public unowned string? undo_label;
    public unowned string? undo_description;
    public unowned string? redo_label;
    public unowned string? redo_description;
}

public class Marlin.UndoManager : GLib.Object {
    public signal void request_menu_update (Marlin.UndoMenuData menu_data);

    public uint undo_levels = 30;
    public bool confirm_delete = false;

    private GLib.Queue<Marlin.UndoActionData> stack = new GLib.Queue<Marlin.UndoActionData> ();
    private uint index = 0;
    private bool undo_redo_flag = false;

    public static unowned Marlin.UndoManager instance () {
        static UndoManager _instance;
        if (_instance == null) {
            _instance = new Marlin.UndoManager ();
        }
        
        return _instance;
    }

    private void do_menu_update () {
        var menu_data = Marlin.UndoMenuData ();
        lock (stack) {
            var action = get_next_undo_action ();
            if (action != null) {
                menu_data.undo_label = action.get_undo_label ();
                menu_data.undo_description = action.get_undo_description ();
            }

            action = get_next_redo_action ();
            if (action != null) {
                menu_data.redo_label = action.get_redo_label ();
                menu_data.redo_description = action.get_redo_description ();
            }
        }

        /* Update menus */
        request_menu_update (menu_data);
    }

    private Marlin.UndoActionData? get_next_redo_action () {
        if (stack.is_empty ())
            return null;

        if (index == 0) {
            return null;
        }

        return stack.peek_nth (index - 1);
    }

    private Marlin.UndoActionData? get_next_undo_action () {
        if (stack.is_empty ())
            return null;

        var stack_size = stack.get_length ();
        if (index == stack_size) {
            return null;
        }

        var action = stack.peek_nth (index);
    }

    private static void stack_clear_n_oldest (GLib.Queue stack, uint n) {
        for (uint i = 0; i < n; i++) {
            var data = stack.pop_tail ();
            if (data == null) {
                break;
            }

            /*if (action->locked) {
                action->freed = TRUE;
            } else {
                free_undo_action (action, NULL);
            }*/
        }
    }

    private void stack_fix_size () {
        uint length = stack.get_length ();
        if (length > undo_levels) {
            if (index > undo_levels + 1) {
                /* If the index will fall off the stack
                 * move it back to the maximum position */
                index = undo_levels + 1;
            }

            stack_clear_n_oldest (stack, length - undo_levels);
        }
    }

    private void clear_redo_actions () {
        while (index > 0) {
            stack.pop_head ();
            index--;
        }
    }

    private void stack_push_action (Marlin.UndoActionData action) {
        clear_redo_actions ();
        stack.push_head (action);
        var length = stack.get_length ();
        if (length > undo_levels) {
            stack_fix_size ();
        }
    }

    public void add_action (Marlin.UndoActionData action) {
        action.manager = this;
        lock (stack) {
            stack_push_action (action);
        }

        do_menu_update ();
    }

    public void add_rename_action (GLib.File file, string original_name) {
        var action_data = new Marlin.UndoActionData (Marlin.UndoActionData.Type.RENAME, 1);
        action_data.old_uri = file.get_parent ().get_child (original_name).get_path ();
        new_uri = file.get_uri ();
        add_action (action_data);
    }

    public void undo (Gtk.Widget parent_view, Marlin.UndoFinishCallback) {
        
    }

    public void redo (Gtk.Widget parent_view, Marlin.UndoFinishCallback) {
        
    }

    public bool is_undo_redo () {
        return undo_redo_flag;
    }

    public void trash_has_emptied () {
        
    }
}
