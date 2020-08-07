// Dialogs module definition.
// Written in the D programming language.
// Copyright (C) 2020 David Terhune
// Distributed under the Boost Software License, version 1.0.
module dialogs;

import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.msgbox;

import std.array;
import std.conv;

/// Dialog type enumeration.  Doubles as dialog title prefix.
enum DialogType : dstring
{
    CREATE = "Create "d,
    EDIT = "Edit "d,
}

/// Dialog type for creating or editing a checklist
class CreateEditListDialog : Dialog
{
    private EditLine _listName;
    private EditLine _boxCount;

    private dstring _name;
    private int _boxes = 1;

    /++
    Constructor

    Params:
        type = dialog type
        parent = parent window
    +/
    this(DialogType type, Window parent)
    {
        super(UIString.fromRaw(type ~ "List"d), parent, DialogFlag.Modal,
            parent.width / 2, parent.height / 2);
    }

    /++
    Checklist name

    Returns: name
    +/
    @property dstring name()
    {
        return _name;
    }

    /++
    Checklist name

    Params: s = name

    Returns: this
    +/
    @property CreateEditListDialog name(dstring s)
    {
        _name = s;
        return this;
    }

    /++
    Number of boxes per row.

    Returns: boxes
    +/
    @property int boxes()
    {
        return _boxes;
    }

    /++
    Number of boxes per row.

    Params: b = boxes

    Returns: this
    +/
    @property CreateEditListDialog boxes(int b)
    {
        _boxes = b;
        return this;
    }

    override bool closeWithDefaultAction()
    {
        return handleAction(ACTION_OK);
    }

    override bool handleAction(const Action action)
    {
        if (action.id == StandardAction.Cancel)
        {
            super.handleAction(action);
            return true;
        }
        if (action.id == StandardAction.Ok)
        {
            // Validate contents
            if (_listName.text.length == 0)
            {
                // List name cannot be empty - show popup
                window.showMessageBox("Error"d, "List name cannot be empty"d);
                return true;
            }
            if (_boxCount.text.to!int <= 0)
            {
                // Number of boxes must be greater than or equal to 1
                window.showMessageBox("Error"d, "Number of boxes must be >= 1"d);
                return true;
            }
            _name = _listName.text;
            _boxes = _boxCount.text.to!int;
        }
        return super.handleAction(action);
    }

    override void initialize()
    {
        _listName = new EditLine(null, _name);
        _listName.minWidth(150);
        _boxCount = new EditLine(null, _boxes.to!dstring);
        
        TableLayout tl = new TableLayout().colCount(2);
        tl.addChild(new TextWidget(null, "List Name"d));
        tl.addChild(_listName);
        tl.addChild(new TextWidget(null, "Num Boxes"d));
        tl.addChild(_boxCount);

        addChild(tl);
        addChild(createButtonsPanel([ACTION_OK, ACTION_CANCEL], 0, 0));
    }
}

/// Dialog for creating or editing an item in a checklist
class CreateEditListItemDialog : Dialog
{
    private EditLine _itemText;

    private dstring _data;

    /++
    Constructor

    Params:
        type = dialog type
        parent = parent window
    +/
    public this(DialogType type, Window parent)
    {
        super(UIString.fromRaw(type ~ "List Item"d), parent, DialogFlag.Modal,
            parent.width / 2, parent.height / 2);
    }

    /++
    Item text data

    Returns: data
    +/
    @property dstring data()
    {
        return _data;
    }

    /++
    Item text data

    Params: d = data

    Returns: this
    +/
    @property CreateEditListItemDialog data(dstring d)
    {
        _data = d;
        return this;
    }
    
    override bool closeWithDefaultAction()
    {
        return handleAction(ACTION_OK);
    }

    override bool handleAction(const Action action)
    {
        if (action.id == StandardAction.Cancel)
        {
            super.handleAction(action);
            return true;
        }
        if (action.id == StandardAction.Ok)
        {
            // Validate contents
            if (_itemText.text.length == 0)
            {
                // List name cannot be empty - show popup
                window.showMessageBox("Error"d, "Item text cannot be empty"d);
                return true;
            }
            _data = _itemText.text;
        }
        return super.handleAction(action);
    }

    override protected void initialize()
    {
        _itemText = new EditLine(null, _data);
        _itemText.minWidth(150);

        HorizontalLayout hl = new HorizontalLayout();
        hl.addChild(new TextWidget(null, "List Item Text"d));
        hl.addChild(_itemText);

        addChild(hl);
        addChild(createButtonsPanel([ACTION_OK, ACTION_CANCEL], 0, 0));
    }
}

/// Dialog for creating multiple list items simultaneously
class CreateMultipleItemsDialog : Dialog
{
    private EditBox _editBox;
    private dstring[] _items;

    /++
    Constructor.

    Params:
        parent = parent window
    +/
    public this(Window parent)
    {
        super(UIString.fromRaw("Create List Items"d), parent, DialogFlag.Modal,
            parent.width / 2, parent.height / 2);
    }

    /++
    Items.

    Returns: items
    +/
    @property dstring[] items()
    {
        return _items;
    }

    override bool closeWithDefaultAction()
    {
        return handleAction(ACTION_OK);
    }

    override bool handleAction(const Action action)
    {
        if (action.id == StandardAction.Cancel)
        {
            super.handleAction(action);
            return true;
        }
        if (action.id == StandardAction.Ok)
        {
            // Validate contents
            if (_editBox.text.length == 0)
            {
                // List name cannot be empty - show popup
                window.showMessageBox("Error"d, "Item text cannot be empty"d);
                return true;
            }
            _items = _editBox.text.split("\n");
        }
        return super.handleAction(action);
    }

    override void initialize()
    {
        _editBox = new EditBox();
        _editBox.minWidth(150);
        _editBox.minHeight(100);

        addChild(new TextWidget(null, "List Items (one per line)"d));
        addChild(_editBox);

        addChild(createButtonsPanel([ACTION_OK, ACTION_CANCEL], 0, 0));
    }
}

