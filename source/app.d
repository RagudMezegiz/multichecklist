// Multi Check List application
// Written in the D programming language.
// Copyright (C) 2020 David Terhune
// Distributed under the Boost Software License, version 1.0.
import checklist;
import dialogs;

import dlangui;
import dlangui.dialogs.dialog;

/// Program version information
enum versionInfo = "
        Multi-Check-List version 0.3.0
https://github.com/RagudMezegiz/multichecklist

       Copyright (C) 2020 David Terhune
           (dave.terhune@gmail.com)
"d;

mixin APP_ENTRY_POINT;

/++
Entry point for dlangui based application.

Params:
    args = command-line arguments

Returns: exit code
+/
extern (C) int UIAppMain(string[] args)
{
    try
    {
        // Open the data connection
        ChecklistData.open();
        
        // Create window
        Window window = Platform.instance.createWindow("MultiCheckList", null, WindowFlag.Resizable);

        // Create main frame
        window.mainWidget = new MultiCheckListFrame();
        window.windowOrContentResizeMode(WindowOrContentResizeMode.resizeWindow);

        // Show window
        window.show();

        // Run message loop
        return Platform.instance.enterMessageLoop();
    }
    finally
    {
        ChecklistData.close();
    }
}

/// Application IDs for application menu items
enum AppActions : int
{
    FileExit = 0x100,
    ListNew,
    ListEdit,
    ListDelete,
    ListClear,
    ItemNew,
    ItemList,
    HelpAbout
}

/// Application frame
class MultiCheckListFrame : AppFrame
{
    // Menu actions
    private Action ACTION_FILE_EXIT = new Action(AppActions.FileExit, "E&xit"d);
    private Action ACTION_LIST_NEW = new Action(AppActions.ListNew, "New &List"d);
    private Action ACTION_LIST_EDIT = new Action(AppActions.ListEdit, "&Edit List"d);
    private Action ACTION_LIST_DELETE = new Action(AppActions.ListDelete, "&Delete List"d);
    private Action ACTION_LIST_CLEAR = new Action(AppActions.ListClear, "&Clear List"d);
    private Action ACTION_ITEM_NEW = new Action(AppActions.ItemNew, "New &Item"d);
    private Action ACTION_ITEM_LIST = new Action(AppActions.ItemList, "&Multiple New Items"d);
    private Action ACTION_HELP_ABOUT = new Action(AppActions.HelpAbout, "&About"d);

    // Checklist tab widget
    private TabWidget _listTabs;

    /++
    Action handler

    Params:
        a = action

    Returns: true if action was handled, false if not
    +/
    override bool handleAction(const Action a)
    {
        if (!a)
        {
            return false;
        }

        switch (a.id)
        {
            case AppActions.FileExit:
                window.close();
                return true;

            case AppActions.ListNew:
                createNewList();
                return true;

            case AppActions.ListEdit:
                editList();
                return true;

            case AppActions.ListDelete:
                deleteList();
                return true;

            case AppActions.ListClear:
                clearList();
                return true;

            case AppActions.ItemNew:
                createNewListItem();
                return true;

            case AppActions.ItemList:
                createNewItemMultiple();
                return true;

            case AppActions.HelpAbout:
                window.showMessageBox("About Multi-Check-List"d, versionInfo);
                return true;

            default:
                return false;
        }
    }
    
    /// Initialization
    override void initialize()
    {
        _appName = "MultiCheckList";
        super.initialize();
        enableMenuActions();
        statusLine().setStatusText("Ready"d);
    }

    /// Create main menu
    override MainMenu createMainMenu()
    {
        MenuItem mainItems = new MenuItem();

        MenuItem fileItem = new MenuItem(new Action(1, "&File"d));
        fileItem.add(ACTION_FILE_EXIT);
        mainItems.add(fileItem);

        MenuItem listItem = new MenuItem(new Action(2, "&List"d));
        listItem.add(ACTION_LIST_NEW);
        listItem.add(ACTION_LIST_EDIT);
        listItem.add(ACTION_LIST_DELETE);
        listItem.addSeparator();
        listItem.add(ACTION_LIST_CLEAR);
        mainItems.add(listItem);

        MenuItem itemItem = new MenuItem(new Action(3, "&Item"d));
        itemItem.add(ACTION_ITEM_NEW);
        itemItem.add(ACTION_ITEM_LIST);
        mainItems.add(itemItem);

        MenuItem helpItem = new MenuItem(new Action(4, "&Help"d));
        helpItem.add(ACTION_HELP_ABOUT);
        mainItems.add(helpItem);

        MainMenu menu = new MainMenu(mainItems);
        return menu;
    }

    /// Create toolbars
    override ToolBarHost createToolbars()
    {
        // No toolbars at this time
        return null;
    }

    /// Create main window
    override Widget createBody()
    {
        _listTabs = new TabWidget();
        _listTabs.layoutWidth(FILL_PARENT);
        _listTabs.layoutHeight(FILL_PARENT);

        // Load existing lists, if any
        Checklist[] checklists = ChecklistData.load();
        if (checklists !is null)
        {
            foreach (cl ; checklists)
            {
                Log.d("Creating tab ", cl.name);
                CheckListTab tab = new CheckListTab(cl);
                tab.id("checklist_" ~ _listTabs.tabCount.to!string);
                _listTabs.addTab(tab, tab.name);
            }
            _listTabs.selectTab(0);
        }

        return _listTabs;
    }

    /// Enable or disable menu actions according to current state
    private void enableMenuActions()
    {
        const bool haveTabs = _listTabs.tabCount > 0;
        ACTION_LIST_EDIT.state(ActionState(haveTabs, true, false));
        ACTION_LIST_DELETE.state(ActionState(haveTabs, true, false));
        ACTION_ITEM_NEW.state(ActionState(haveTabs, true, false));
    }

    /// Create new list
    private void createNewList()
    {
        CreateEditListDialog dlg = new CreateEditListDialog(DialogType.CREATE, window);
        dlg.dialogResult = delegate(Dialog d, const Action result)
        {
            if (result.id == ACTION_OK.id)
            {
                Checklist cl = ChecklistData.newChecklist(dlg.name, dlg.boxes);
                if (cl is null)
                {
                    statusLine().setStatusText("Failed to create new checklist"d);
                }
                else
                {
                    CheckListTab clt = new CheckListTab(cl);
                    clt.id("checklist_" ~ _listTabs.tabCount.to!string);
                    _listTabs.addTab(clt, clt.name);
                    _listTabs.selectTab(_listTabs.tabCount - 1);
                    statusLine().setStatusText("Created new checklist " ~ clt.name);
                    enableMenuActions();
                    invalidate();
                }
            }
        };
        dlg.show();
    }

    /// Create new list item
    private void createNewListItem()
    {
        CreateEditListItemDialog dlg = new CreateEditListItemDialog(DialogType.CREATE, window);
        dlg.dialogResult = delegate(Dialog d, const Action result)
        {
            if (result.id == ACTION_OK.id)
            {
                CheckListTab clt = _listTabs.childById!CheckListTab(_listTabs.selectedTabId);
                clt.createRow(dlg.data);
                statusLine().setStatusText("Created new list item " ~ dlg.data);
                enableMenuActions();
                invalidate();
            }
        };
        dlg.show();
    }

    /// Create multiple list items at once
    private void createNewItemMultiple()
    {
        CreateMultipleItemsDialog dlg = new CreateMultipleItemsDialog(window);
        dlg.dialogResult = delegate(Dialog d, const Action result)
        {
            if (result.id == ACTION_OK.id)
            {
                CheckListTab clt = _listTabs.childById!CheckListTab(_listTabs.selectedTabId);
                foreach (s; dlg.items)
                {
                    clt.createRow(s);
                }
                statusLine().setStatusText("Created multiple items for list " ~ clt.name);
                enableMenuActions();
                invalidate();
            }
        };
        dlg.show();
    }

    /// Edit list
    private void editList()
    {
        string selected = _listTabs.selectedTabId;
        CheckListTab clt = _listTabs.childById!CheckListTab(selected);

        CreateEditListDialog dlg = new CreateEditListDialog(DialogType.EDIT, window);
        dlg.name(clt.name);
        dlg.boxes(clt.boxes);
        dlg.dialogResult = delegate(Dialog d, const Action result)
        {
            if (result.id == ACTION_OK.id)
            {
                clt.update(dlg.name, dlg.boxes);
                _listTabs.renameTab(selected, dlg.name);
                statusLine().setStatusText("Updated checklist " ~ dlg.name);
                enableMenuActions();
                invalidate();
            }
        };
        dlg.show();
    }

    /// Delete list
    private void deleteList()
    {
        CheckListTab clt = _listTabs.childById!CheckListTab(_listTabs.selectedTabId);

        window.showMessageBox(UIString.fromRaw("Delete "d ~ clt.name ~ "?"d),
            UIString.fromRaw("This cannot be undone. Are you sure?"d),
            [ACTION_YES, ACTION_NO], 1, delegate(const Action a)
            {
                if (a.id == StandardAction.Yes)
                {
                    clt.remove();
                    _listTabs.removeTab(clt.id);
                    if (_listTabs.tabCount > 0)
                    {
                        _listTabs.selectTab(0);
                    }
                    enableMenuActions();
                    invalidate();
                }
                return true;
            });
    }

    /// Clear list
    private void clearList()
    {
        CheckListTab clt = _listTabs.childById!CheckListTab(_listTabs.selectedTabId);

        window.showMessageBox(UIString.fromRaw("Clear "d ~ clt.name ~ "?"d),
            UIString.fromRaw("Are you sure?"d),
            [ACTION_YES, ACTION_NO], 1, delegate(const Action a)
            {
                if (a.id == StandardAction.Yes)
                {
                    clt.clear();
                    enableMenuActions();
                    invalidate();
                }
                return true;
            });
    }
}

