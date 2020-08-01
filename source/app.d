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
         Multi-Check-List version 0.1
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
    ListItemNew,
    ListItemEdit,
    ListItemDelete,
    HelpAbout
}

/// Application frame
class MultiCheckListFrame : AppFrame
{
    // Menu actions
    private Action ACTION_FILE_EXIT = new Action(AppActions.FileExit, "E&xit"d);
    private Action ACTION_LIST_NEW = new Action(AppActions.ListNew, "New &List"d);
    private Action ACTION_LIST_EDIT = new Action(AppActions.ListEdit, "Edit List"d);
    private Action ACTION_LIST_DELETE = new Action(AppActions.ListDelete, "Delete List"d);
    private Action ACTION_LIST_ITEM_NEW = new Action(AppActions.ListItemNew, "New &Item"d);
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
                // TODO Edit selected list
                statusLine().setStatusText("List->Edit List menu handler not implemented");
                return true;

            case AppActions.ListDelete:
                // TODO Delete selected list
                statusLine().setStatusText("List->Delete List menu handler not implemented");
                return true;

            case AppActions.ListItemNew:
                createNewListItem();
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
        listItem.add(ACTION_LIST_ITEM_NEW);
        mainItems.add(listItem);

        MenuItem helpItem = new MenuItem(new Action(3, "&Help"d));
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
        ACTION_LIST_ITEM_NEW.state(ActionState(haveTabs, true, false));
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
}

