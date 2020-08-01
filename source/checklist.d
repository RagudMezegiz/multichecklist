// Checklist module definition.
// Written in the D programming language.
// Copyright (C) 2020 David Terhune
// Distributed under the Boost Software License, version 1.0.
module checklist;

import dialogs;

import d2sqlite3;
import dlangui;
import dlangui.dialogs.dialog;

import std.algorithm;
import std.conv;

/// Data connection
class ChecklistData
{
    private enum dataLocation = "checklist.db";
    private enum lastRowInserted = "SELECT last_insert_rowid()";
    
    private enum createLists = "CREATE TABLE IF NOT EXISTS " ~
        "lists (id INTEGER PRIMARY KEY, name TEXT UNIQUE, boxes INTEGER)";
    private enum insertLists = "INSERT INTO lists (name, boxes) VALUES (:name, :boxes)";
    private enum selectLists = "SELECT * FROM lists";
    private enum updateListBoxes = "UPDATE lists SET boxes = :boxes WHERE id == :id";

    private enum createListData = "CREATE TABLE IF NOT EXISTS " ~
        "list_data (id INTEGER PRIMARY KEY, list_id INTEGER, flags INTEGER, data TEXT, " ~
        "FOREIGN KEY(list_id) REFERENCES list(id))";
    private enum insertListData = "INSERT INTO list_data (list_id, flags, data) VALUES (:id, :flags, :data)";
    private enum selectListData = "SELECT * FROM list_data WHERE list_id == :id ORDER BY data ASC";
    private enum updateListDataData = "UPDATE list_data SET data = :data WHERE id == :id";
    private enum updateListDataFlags = "UPDATE list_data SET flags = :flags WHERE id == :id";

    // Database connection
    private static Database db;

    /++
    Load any pre-existing checklist data.

    Returns: checklists
    +/
    public static Checklist[] load()
    {
        Checklist[] result;
        
        // Get the lists; for each list, populate the rows
        foreach (list ; db.execute(selectLists))
        {
            Checklist cl = new Checklist(list[0].as!int, list[1].as!dstring, list[2].as!int);
            foreach (row ; db.execute(selectListData, list[0].as!int))
            {
                cl.addRow(new CheckRow(row[0].as!int, row[2].as!int, row[3].as!dstring));
            }
            result ~= cl;
        }
        return result;
    }

    /// Open the data connection
    public static void open()
    {
        db = Database(dataLocation);
        initData();
    }

    /// Close the data connection
    public static void close()
    {
        db.close();
    }

    /++
    Create a new checklist.

    Params:
        name = list name
        nBoxes = number of boxes per row

    Returns: checklist
    +/
    public static Checklist newChecklist(dstring name, int nBoxes)
    {
        db.execute(insertLists, name, nBoxes);
        const int row_id = db.execute(lastRowInserted).oneValue!int;
        Log.d("Inserted checklist row ", row_id);
        return new Checklist(row_id, name, nBoxes);
    }

    /++
    Create a new checklist item.

    Params:
        list_id = list identifier
        data = item data

    Returns: checklist row
    +/
    public static CheckRow newChecklistItem(int list_id, dstring data)
    {
        db.execute(insertListData, list_id, 0, data);
        const int row_id = db.execute(lastRowInserted).oneValue!int;
        Log.d("Inserted checklist data row ", row_id);
        return new CheckRow(row_id, 0, data);
    }

    /++
    Update the data value for a row.

    Params:
        row_id = row identifier
        data = new data value
    +/
    public static void updateListData(int row_id, dstring data)
    {
        db.execute(updateListDataData, data, row_id);
        Log.d("Updated data: ", row_id, ", ", data);
    }

    /++
    Update the flags value for a row.

    Params:
        row_id = row identifier
        flags = new flags value
    +/
    public static void updateListData(int row_id, int flags)
    {
        db.execute(updateListDataFlags, flags, row_id);
        Log.d("Updated data flags: ", row_id, ", ", flags);
    }

    // Create the initial tables if they're not there.
    private static initData()
    {
        db.execute(createLists);
        db.execute(createListData);
    }
}

/// Set of boolean flags accessed via indexing operators.
struct CheckFlags
{
    /// Flags as an integer.
    int _value;

    /++
    Index operator 'value = this[index]'

    Params:
        index = flag index

    Returns: flag value
    +/
    bool opIndex(size_t index) const
    {
        return cast(bool)(_value & (1 << index));
    }

    /++
    Index assignment operator 'this[index] = value'

    Params:
        value = new flag value
        index = flag index

    Returns: assigned value
    +/
    bool opIndexAssign(bool value, size_t index)
    {
        if (value)
        {
            _value |= 1 << index;
        }
        else
        {
            _value &= ~(1 << index);
        }
        return value;
    }
}

unittest
{
    CheckFlags flags = CheckFlags(0);
    assert(flags._value == 0);
    flags[1] = true;
    assert(flags._value == 2);
    flags[0] = true;
    assert(flags._value == 3);
    flags[1] = false;
    assert(flags._value == 1);
}

/// A single row of a checklist
class CheckRow
{
    private int _row;
    private dstring _text;
    private CheckFlags _flags;

    /// Row text
    /// Returns: row text
    @property dstring text()
    {
        return _text;
    }

    /// Row text
    /// Params: t = row text
    @property void text(dstring t)
    {
        _text = t;
        ChecklistData.updateListData(_row, _text);
    }

    /++
    Constructor

    Params:
        flags = flags value
        text = row text
    +/
    public this(int row_id, int flags, dstring text)
    {
        _row = row_id;
        _text = text;
        _flags = CheckFlags(flags);
    }

    /++
    Get the checked state.

    Params:
        index = checkbox index

    Returns: checked state
    +/
    public bool isChecked(size_t index) const
    {
        return _flags[index];
    }

    /++
    Set a box to checked.

    Params:
        index = checkbox index
    +/
    public void setCheck(size_t index)
    {
        _flags[index] = true;
        ChecklistData.updateListData(_row, _flags._value);
    }

    /++
    Set a box to unchecked.

    Params:
        index = checkbox index
    +/
    public void clearCheck(size_t index)
    {
        _flags[index] = false;
        ChecklistData.updateListData(_row, _flags._value);
    }

    /++
    Comparison for ordering.

    Params:
        obj = object to compare with

    Returns: -1,0,1 as per method contract
    +/
    public override int opCmp(Object obj) const
    {
        CheckRow other = cast(CheckRow)obj;
        return _text.cmp(other._text);
    }
}

/// A single checklist
class Checklist
{
    private int _id;
    private dstring _name;
    private int _boxes;
    private CheckRow[] _rows;

    /++
    Constructor

    Params:
        name = list name
        nBoxes = number of checkboxes to show
    +/
    this(int row_id, dstring name, int nBoxes)
    {
        _id = row_id;
        _name = name;
        _boxes = nBoxes;
    }

    /++
    Checklist name
    
    Returns: checklist name
    +/
    @property dstring name()
    {
        return _name;
    }

    /++
    Number of boxes per row

    Returns: boxes
    +/
    @property int boxes()
    {
        return _boxes;
    }
    
    /++
    Number of boxes per row

    Params:
        nBoxes = number of boxes
    +/
    @property void boxes(int nBoxes)
    {
        _boxes = nBoxes;
    }

    /++
    Rows

    Returns: rows
    +/
    @property CheckRow[] rows()
    {
        return _rows;
    }

    /++
    Add a row to the list.

    Params:
        row = row to add
    +/
    public void addRow(CheckRow row)
    {
        _rows ~= row;
    }

    /++
    Create a new row and add it to the list.

    Params:
        text = item text
    +/
    public void createRow(dstring text)
    {
        _rows ~= ChecklistData.newChecklistItem(_id, text);
    }

    /++
    Get the value of a checkbox.

    Params:
        row = row index
        box = box index on the row

    Returns: checked state
    +/
    public bool isChecked(size_t row, size_t box) const
    {
        return _rows[row].isChecked(box);
    }

    /++
    Set a checkbox.

    Params:
        row = row index
        box = box index on row
    +/
    public void setCheck(size_t row, size_t box)
    {
        _rows[row].setCheck(box);
    }

    /++
    Clear a checkbox.

    Params:
        row = row index
        box = box index on row
    +/
    public void clearCheck(size_t row, size_t box)
    {
        _rows[row].clearCheck(box);
    }
}

/// Checklist tab
class CheckListTab : TableLayout
{
    /// Checklist contained in the tab
    Checklist _list;

    /++
    Constructor

    Params:
        checklist = contained checklist
    +/
    public this(Checklist checklist)
    {
        _list = checklist;
        colCount(4);
        buildLayout();
    }
    
    /++
    Tab name

    Returns: tab name
    +/
    @property dstring name()
    {
        return _list.name;
    }

    /++
    Create a new row

    Params:
        text = row text
    +/
    public void createRow(dstring text)
    {
        _list.createRow(text);
        addRowControls(_list.rows.length - 1, _list.rows[$-1]);
    }

    /// Build the table layout
    private void buildLayout()
    {
        foreach (i, cr ; _list.rows)
        {
            addRowControls(i, cr);
        }
    }

    /// Add a new set of row controls
    private void addRowControls(size_t i, CheckRow row)
    {
        HorizontalLayout hl = new HorizontalLayout();
        foreach (j ; 0 .. _list.boxes)
        {
            CheckBox b = new CheckBox("check_" ~ i.to!string ~ "_" ~ j.to!string);
            b.checked(_list.isChecked(i, j));
            b.checkChange = &(new CheckDelegate(_list, i, j).handleCheck);
            hl.addChild(b);
        }
        addChild(hl);
        addChild(new TextWidget("text_" ~ i.to!string, row.text));
        Button ed = new Button(new Action(i.to!int, "Edit"d));
        ed.click = &onEdit;
        addChild(ed);
        Button del = new Button(new Action(-i.to!int, "Delete"d));
        del.click = &onDelete;
        addChild(del);
    }

    bool onEdit(Widget w)
    {
        CreateEditListItemDialog dlg = new CreateEditListItemDialog(DialogType.EDIT, window);
        dlg.data(_list.rows[w.action.id].text);
        dlg.dialogResult = delegate(Dialog d, const Action result)
        {
            if (result.id == ACTION_OK.id)
            {
                _list.rows[w.action.id].text(dlg.data);
                childById!TextWidget("text_" ~ w.action.id.to!string).text(dlg.data);
                invalidate();
            }
        };
        dlg.show();
        return true;
    }

    bool onDelete(Widget w)
    {
        // TODO Implement
        return true;
    }
}

/// Delegate for checkbox handler
class CheckDelegate
{
    private Checklist _list;
    private size_t _i;
    private size_t _j;

    /++
    Constructor

    Params:
        list = checklist
        i = row index
        j = checkbox index
    +/
    public this(Checklist list, size_t i, size_t j)
    {
        _list = list;
        _i = i;
        _j = j;
    }

    /++
    Check handler.

    Params:
        w = checkbox widget
        b = flag indicating checked

    Returns: true indicating event was handled
    +/
    public bool handleCheck(Widget w, bool b)
    {
        if (b) _list.setCheck(_i, _j);
        else _list.clearCheck(_i, _j);
        return true;
    }
}

