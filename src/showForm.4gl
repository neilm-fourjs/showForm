-- Program for testing Screen Forms.
-- Arg 1 : form name ( without extension )
-- Arg 2 : 1/2 Mode: 1=simple form preview / 2=testcase preview from sub directory.
-- Arg 3 : 0/1 MDI TRUE/FALSE ( optional ) default is false
IMPORT os

CONSTANT abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

DEFINE m_formname STRING
DEFINE m_ask, m_auto, m_toolbar SMALLINT

DEFINE m_autofill, m_dbgtxt STRING
DEFINE m_mdi, ad_name, st_name STRING

MAIN

	LET m_autofill = FALSE
	LET m_toolbar = FALSE
	LET m_auto = TRUE

	LET ad_name = "default"
	LET st_name = "default"

	LET m_formname = ARG_VAL(1)

	LET m_mdi = ARG_VAL(2)
	IF m_mdi IS NULL OR m_mdi = " " THEN
		LET m_mdi = FALSE
	END IF

	CASE m_mdi
		WHEN "S"
			LET m_dbgtxt = "SDI"
		WHEN "M"
			LET m_dbgtxt = "MDI Container"
		WHEN "C"
			LET m_dbgtxt = "MDI Child"
	END CASE

	IF ARG_VAL(3) = "NOTAUTO" THEN
		MESSAGE m_dbgtxt, ":Preferences Not Applied"
		LET m_auto = FALSE
	END IF

	CASE m_mdi
		WHEN "M"
			CALL ui.Interface.setText("MDI Container")
			CALL ui.Interface.setType("container")
			CALL ui.Interface.setName("MDIcontain")
			CALL load_tb(TRUE, "container")
			CALL add_tm()
			RUN "testform " || m_formname || " 2" WITHOUT WAITING
			CALL doMenu()
			EXIT PROGRAM
		WHEN "C"
			CALL ui.Interface.setType("child")
			CALL ui.Interface.setContainer("MDIcontain")
	END CASE

	CALL ui.Form.setDefaultInitializer("init_form")

	IF m_formname = "ASK" THEN
		CALL sel_form()
	ELSE
		IF NOT os.path.exists(m_formname || ".42f") THEN
			CALL fgl_winMessage("Error", SFMT("Form '%1' not found", m_formname), "exclamation")
			EXIT PROGRAM
		END IF
		DISPLAY m_dbgtxt, ":Opening form: ", m_formname
		OPEN FORM astab FROM m_formname
		DISPLAY FORM astab
	END IF

	IF m_autofill THEN
		CALL auto_fillform()
	END IF

	CALL doMenu()

END MAIN
--------------------------------------------------------------------------------
FUNCTION loadResources()
	IF st_name IS NOT NULL THEN
		TRY
			CALL ui.interface.loadStyles(st_name)
		CATCH
			DISPLAY m_dbgtxt, ":Styles '" || st_name || "' NOT loaded! "
		END TRY
	END IF
	IF ad_name IS NOT NULL THEN
		TRY
			CALL ui.interface.loadActionDefaults(ad_name)
		CATCH
			DISPLAY m_dbgtxt, ":Actions '" || st_name || "' NOT loaded! "
		END TRY
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION doMenu()

	MENU "Options"
		ON ACTION tf_open_form
			CALL sel_form()
			DISPLAY "Opening form: ", m_formname
			OPEN FORM astab FROM m_formname
			DISPLAY FORM astab

		ON ACTION tf_init_form
			CALL init_form(get_form())

		ON ACTION tf_list_obj
			CALL list_ele("*")

		ON ACTION tf_hide
			CALL hide(NULL, 1)

		ON ACTION tf_unhide
			CALL hide(NULL, 0)

		ON ACTION tf_autofill
			CALL auto_fillform()

		ON ACTION tf_dump
			CALL dump()

		ON ACTION accept
			EXIT MENU
		ON ACTION cancel
			EXIT MENU
		ON ACTION close
			EXIT MENU
		ON ACTION exit
			EXIT MENU
	END MENU

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION init_form(fn ui.Form)
	DEFINE l_formname STRING

	LET l_formname = fn.getNode().getAttribute("name")

	CASE l_formname
		WHEN "xxx"
-- custom forms ?
		OTHERWISE
			CALL auto_fillform()
	END CASE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION auto_fillform()
	DEFINE fn ui.Form
	DEFINE n om.domNode
	DEFINE nl om.NodeList
	DEFINE x SMALLINT

	LET fn = get_form()
	IF fn IS NULL THEN
		RETURN
	END IF
	LET n = fn.getNode()

	LET nl = n.selectByPath("//FormField")
	FOR x = 1 TO nl.getLength()
		CALL auto_fillform2(fn, nl.item(x))
	END FOR

	LET nl = n.selectByPath("//TableColumn")
	FOR x = 1 TO nl.getLength()
		CALL auto_fillform2(fn, nl.item(x))
	END FOR

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION auto_fillform2(fn, n)
	DEFINE fn ui.Form
	DEFINE n, n1 om.domNode
	DEFINE nl om.NodeList
	DEFINE x, y SMALLINT
	DEFINE val STRING

	LET n1 = n.getFirstChild()
	LET val = ""
	IF n1.getTagName() = "DateEdit" THEN
		LET val = TODAY
	END IF
	IF n1.getTagName() = "Edit" OR n1.getTagName() = "ButtonEdit" OR n1.getTagName() = "RipFIELD_BMP"
			THEN
--		LET y = n1.getAttribute("width")
		LET y = n1.getAttribute("gridWidth")
		IF y IS NULL OR y = 0 THEN
			LET y = 1
		END IF
		IF y > 36 THEN
			LET y = 36
		END IF
		LET val = abc.subString(1, y)
		IF n.getAttribute("numAlign") = "1" THEN
			LET val = "1"
		END IF
	END IF
	IF n1.getTagName() = "Label" THEN
		IF n1.getAttribute("value") IS NULL THEN
			LET y = n1.getAttribute("width")
			IF y IS NULL OR y > 7 THEN
				LET val = "DynLabel"
			ELSE
				LET val = "DynLabel"
				LET val = val.subString(1, y)
			END IF
		END IF
	END IF
	IF n.getTagName() = "FormField" THEN
		CALL n.setAttribute("value", val)
	ELSE
		LET nl = n.selectByPath("//Value")
		FOR x = 1 TO nl.getLength()
			DISPLAY "Filling Table"
			LET n = nl.item(x)
			CALL n.setAttribute("value", val)
		END FOR
	END IF

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION get_form()
	DEFINE w ui.Window
	DEFINE f ui.Form

--	LET w = ui.Window.getCurrent()
	LET w = ui.Window.forName("screen")
	LET f = w.getForm()

	RETURN f
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION hide(nam, on_off)
	DEFINE on_off SMALLINT
	DEFINE nam STRING
	DEFINE f ui.Form

	LET f = get_form()

	IF nam IS NULL THEN
		PROMPT "Enter Name:" FOR nam
		IF nam IS NULL THEN
			RETURN
		END IF
	END IF

	WHENEVER ERROR CONTINUE
	CALL f.setElementHidden(nam, on_off)
	IF STATUS != 0 THEN
		ERROR "Item not found!"
	END IF
	WHENEVER ERROR STOP

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION dump()
	DEFINE f ui.Form
	DEFINE n om.domNode

	LET f = get_form()
	LET n = f.getNode()
	CALL n.writeXML(m_formName || ".xml")
	MESSAGE "Dumped to '" || m_formName || ".xml'"

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION mk_listwin(cols, titl, colt1, colt2, colt3)
	DEFINE cols, x SMALLINT
	DEFINE titl, colt1, colt2, colt3 STRING
	DEFINE win ui.Window
	DEFINE frm ui.Form
	DEFINE win_n, frm_n, vbox, tabl, tabc, edit om.domNode

	LET win = ui.Window.getCurrent()
	LET win_n = win.getNode()
	CALL win_n.setAttribute("style", "dialog")
	CALL win_n.setAttribute("text", titl)
	LET frm = win.createForm("list")
	LET frm_n = frm.getNode()
	LET vbox = frm_n.createChild('VBox')

	LET tabl = vbox.createChild('Table')
	CALL tabl.setAttribute("tabName", "list")
	CALL tabl.setAttribute("width", 30)
	CALL tabl.setAttribute("height", "20")
	CALL tabl.setAttribute("pageSize", "10")
	CALL tabl.setAttribute("size", "10")
	FOR x = 1 TO cols
		LET tabc = tabl.createChild('TableColumn')
		CALL tabc.setAttribute("colName", "fld" || x)
		LET edit = tabc.createChild('Edit')
		CASE x
			WHEN 1
				CALL tabc.setAttribute("text", colt1)
			WHEN 2
				CALL tabc.setAttribute("text", colt2)
			WHEN 3
				CALL tabc.setAttribute("text", colt3)
		END CASE
		CALL edit.setAttribute("width", 15)
	END FOR

	CALL ui.interface.refresh()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION list_ele(what)
	DEFINE what STRING
	DEFINE f ui.Form
	DEFINE nl om.NodeList
	DEFINE n om.domNode
	DEFINE x SMALLINT
	DEFINE rec DYNAMIC ARRAY OF RECORD
		col1 STRING,
		col2 STRING,
		col3 SMALLINT
	END RECORD

	IF what IS NULL THEN
		LET what = "*"
	END IF

	LET f = get_form()
	LET n = f.getNode()

	LET nl = n.selectByPath("//" || what.trim())
	FOR x = 1 TO nl.getLength()
		LET n = nl.item(x)
		CASE n.getTagName()
			WHEN "Grid"
				CONTINUE FOR
			WHEN "Link"
				CONTINUE FOR
			WHEN "FormField"
				CONTINUE FOR
			WHEN "Value"
				CONTINUE FOR
			WHEN "ValueList"
				CONTINUE FOR
			WHEN "SpacerItem"
				CONTINUE FOR
			WHEN "ToolBar"
				CONTINUE FOR
			WHEN "ToolBarItem"
				CONTINUE FOR
			WHEN "ToolBarSeparator"
				CONTINUE FOR
			WHEN "TopMenu"
				CONTINUE FOR
			WHEN "TopMenuGroup"
				CONTINUE FOR
			WHEN "TopMenuCommand"
				CONTINUE FOR
			WHEN "TopMenuSeparator"
				CONTINUE FOR
			WHEN "RecordView"
				CONTINUE FOR
			WHEN "VBox"
				CONTINUE FOR
			WHEN "HBox"
				CONTINUE FOR
			WHEN "Form"
				CONTINUE FOR
		END CASE
		LET rec[rec.getLength() + 1].col1 = n.getTagName()
		LET rec[rec.getLength()].col2 = n.getAttribute("name")
		LET rec[rec.getLength()].col3 = n.getAttribute("hidden")
		IF rec[rec.getLength()].col3 IS NULL THEN
			LET rec[rec.getLength()].col3 = 0
		END IF
		DISPLAY n.getAttribute("hidden"), ":", n.getTagName(), ":", n.getAttribute("name")
	END FOR

	OPEN WINDOW listele AT 1, 1 WITH 1 ROWS, 1 COLUMNS
	CALL mk_listwin(3, "Elements", "Type", "Name", "Hidden")

	DISPLAY ARRAY rec TO list.* ATTRIBUTE(COUNT = rec.getLength(), UNBUFFERED)
		ON ACTION toggle
			IF rec[arr_curr()].col2 IS NULL OR rec[arr_curr()].col2 = " " THEN
				ERROR "Can't hide/unhide unnamed elements."
				DISPLAY "Can't hide/unhide unnamed elements."
			ELSE
				LET rec[arr_curr()].col3 = NOT rec[arr_curr()].col3
				CALL hide(rec[arr_curr()].col2, rec[arr_curr()].col3)
			END IF
	END DISPLAY

	CLOSE WINDOW listele

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION sel_form()
	DEFINE rec DYNAMIC ARRAY OF RECORD
		col1 STRING
	END RECORD
	DEFINE x, ret SMALLINT
	DEFINE cmd, line STRING
	DEFINE fil_pip base.Channel
	DEFINE tok base.StringTokenizer

	LET cmd = "ls -1 *.42f"

	LET fil_pip = base.Channel.create()
	CALL fil_pip.openpipe(cmd, "r")
	LET ret = 1
	WHILE ret = 1
		LET ret = fil_pip.read(line)
		IF ret = 1 THEN
			LET tok = base.StringTokenizer.create(line, "/")
			WHILE tok.hasMoreTokens()
				LET line = tok.nextToken()
			END WHILE
			LET x = line.getIndexOf(".", 1)
			LET rec[rec.getLength() + 1].col1 = line.subString(1, x - 1)
		END IF
	END WHILE

	OPEN WINDOW listwin AT 1, 1 WITH 1 ROWS, 1 COLUMNS
	CALL mk_listwin(1, "Select Form", "Name", "", "")

	LET m_autofill = FALSE
	DISPLAY ARRAY rec TO list.* ATTRIBUTE(COUNT = rec.getLength())
		ON ACTION reset
			DISPLAY "test"
		ON ACTION tf_autofill
			LET m_autofill = TRUE
			EXIT DISPLAY
		ON ACTION ACCEPT
			RUN "fglrun showForm " || rec[arr_curr()].col1
	END DISPLAY
	IF int_flag THEN
		EXIT PROGRAM
	END IF

	CLOSE WINDOW listwin

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION load_tb(load, nam)
	DEFINE load SMALLINT
	DEFINE nam STRING
	DEFINE n om.domNode
	DEFINE nl om.NodeList

	IF load THEN
		WHENEVER ERROR CONTINUE
		CALL ui.interface.loadToolbar(nam)
		IF STATUS != 0 THEN
			DISPLAY m_dbgtxt, ":Toolbar - '" || nam || "' - not loaded!"
		ELSE
			DISPLAY m_dbgtxt, ":Toolbar - '" || nam || "' - loaded"
		END IF
		WHENEVER ERROR STOP
	ELSE
		LET n = ui.interface.getRootNode()
		LET nl = n.selectByPath("//ToolBar")
		IF nl.getLength() > 0 THEN
			CALL n.removeChild(nl.item(1))
		END IF
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION add_tm()
	DEFINE r, m, mg, n om.domNode
	DEFINE nl om.NodeList

	LET r = ui.interface.getRootNode()
	LET nl = r.selectByPath("//TopMenu")
	IF nl.getLength() > 0 THEN
		RETURN
	END IF
	LET m = r.createChild("TopMenu")
	LET mg = m.createChild("TopMenuGroup")
	CALL mg.setAttribute("text", "File")
	LET n = mg.createChild("TopMenuCommand")
	CALL n.setAttribute("text", "exit")
	CALL n.setAttribute("name", "exit")

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION hidden(f)
	DEFINE f ui.Form
	DEFINE ar DYNAMIC ARRAY OF RECORD
		a1 CHAR(3),
		a2 DATE,
		a3 CHAR(1)
	END RECORD

	CALL f.setElementHidden("formonly.field5", TRUE)
	CALL f.setElementHidden("lab5", TRUE)

	LET ar[1].a1 = "abc"
	LET ar[1].a2 = TODAY
	LET ar[1].a3 = "Y"
	LET ar[2].a1 = "def"
	LET ar[2].a2 = TODAY - 1
	LET ar[2].a3 = "N"
	LET ar[3].a1 = "ghi"
	LET ar[3].a2 = TODAY - 2
	LET ar[3].a3 = ""

	MESSAGE "Before Input"
	INPUT ARRAY ar
			WITHOUT DEFAULTS
			FROM arr.*
			ATTRIBUTES(APPEND ROW = FALSE, INSERT ROW = FALSE, DELETE ROW = FALSE)
	IF int_flag THEN
		RETURN
	END IF

	MESSAGE "Processing..."
	CALL ui.interface.refresh()
	SLEEP 10
	MESSAGE "Finished."

END FUNCTION
--------------------------------------------------------------------------------
