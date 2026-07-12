/*
 * Pure GTK4 C example replicating the InitialSetupDialog layout.
 * Uses proper GTK4 layout containers for correct resize behavior.
 *
 * Layout:
 *   GtkWindow (640x520)
 *   └─ GtkBox (vertical)
 *      ├─ GtkDrawingArea  (welcome header, h=48)
 *      ├─ GtkBox (horizontal, vexpand)
 *      │  ├─ GtkScrolledWindow (tree view, w=159)
 *      │  ├─ GtkSeparator      (vertical)
 *      │  └─ GtkNotebook       (hexpand)
 *      └─ GtkBox (button panel, margin=10)
 *          ├─ spacer (hexpand)
 *          └─ GtkButton ("Start IDE")
 *
 * Compile:
 *   gcc -o test_native_gtk4 test_native_gtk4.c $(pkg-config --cflags --libs gtk4)
 *
 * Run:
 *   ./test_native_gtk4
 */
#include <gtk/gtk.h>
#include <stdio.h>

/* Dump widget allocation for debugging */
static void dump_widget(const char *name, GtkWidget *w) {
    int aw = gtk_widget_get_allocated_width(w);
    int ah = gtk_widget_get_allocated_height(w);
    printf("  %-20s alloc=%dx%d\n", name, aw, ah);
}

static GtkWidget *g_vbox;
static GtkWidget *g_notebook;
static GtkWidget *g_treeview_sw;
static GtkWidget *g_separator;
static GtkWidget *g_btn_box;
static GtkWidget *g_header;
static GtkWidget *g_button;

static void draw_header(GtkDrawingArea *area, cairo_t *cr,
                        int width, int height, gpointer data) {
    /* Blue header background */
    cairo_set_source_rgb(cr, 0.2, 0.4, 0.8);
    cairo_rectangle(cr, 0, 0, width, height);
    cairo_fill(cr);

    /* White text */
    cairo_set_source_rgb(cr, 1, 1, 1);
    cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size(cr, 16);
    cairo_move_to(cr, 10, 30);
    cairo_show_text(cr, "Welcome to Lazarus IDE - Test Layout (native GTK4)");
}

static gboolean dump_after_show(gpointer data) {
    printf("\n=== Native GTK4 widget allocations ===\n");
    dump_widget("VBox", g_vbox);
    dump_widget("Header", g_header);
    dump_widget("TreeView(SW)", g_treeview_sw);
    dump_widget("Separator", g_separator);
    dump_widget("BtnBox", g_btn_box);
    dump_widget("GtkNotebook", g_notebook);
    dump_widget("Button", g_button);

    /* Check notebook internal children */
    GtkWidget *child = gtk_widget_get_first_child(g_notebook);
    int idx = 0;
    while (child) {
        const char *type_name = G_OBJECT_TYPE_NAME(child);
        int cw = gtk_widget_get_allocated_width(child);
        int ch = gtk_widget_get_allocated_height(child);
        printf("  Notebook.child[%d] [%s] alloc=%dx%d\n", idx, type_name, cw, ch);
        child = gtk_widget_get_next_sibling(child);
        idx++;
    }

    fflush(stdout);
    return G_SOURCE_REMOVE;
}

static void on_activate(GtkApplication *app, gpointer data) {
    GtkWidget *window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "Test InitialSetupDialog Layout (native GTK4)");
    gtk_window_set_default_size(GTK_WINDOW(window), 640, 520);
    gtk_window_set_resizable(GTK_WINDOW(window), TRUE);

    /* --- Main vertical box --- */
    g_vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_window_set_child(GTK_WINDOW(window), g_vbox);

    /* --- Welcome header (48px, top) --- */
    g_header = gtk_drawing_area_new();
    gtk_drawing_area_set_content_height(GTK_DRAWING_AREA(g_header), 48);
    gtk_drawing_area_set_draw_func(GTK_DRAWING_AREA(g_header), draw_header, NULL, NULL);
    gtk_box_append(GTK_BOX(g_vbox), g_header);

    /* --- Middle section: horizontal box (expands vertically) --- */
    GtkWidget *hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_widget_set_vexpand(hbox, TRUE);
    gtk_widget_set_margin_top(hbox, 6);
    gtk_box_append(GTK_BOX(g_vbox), hbox);

    /* --- TreeView in ScrolledWindow (fixed width 159) --- */
    g_treeview_sw = gtk_scrolled_window_new();
    gtk_widget_set_size_request(g_treeview_sw, 159, -1);
    gtk_widget_set_margin_start(g_treeview_sw, 6);

    GtkWidget *listbox = gtk_list_box_new();
    for (int i = 0; i < 6; i++) {
        char buf[32];
        snprintf(buf, sizeof(buf), "Item %d", i);
        GtkWidget *label = gtk_label_new(buf);
        gtk_widget_set_halign(label, GTK_ALIGN_START);
        gtk_list_box_append(GTK_LIST_BOX(listbox), label);
    }
    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(g_treeview_sw), listbox);
    gtk_box_append(GTK_BOX(hbox), g_treeview_sw);

    /* --- Separator (splitter) --- */
    g_separator = gtk_separator_new(GTK_ORIENTATION_VERTICAL);
    gtk_box_append(GTK_BOX(hbox), g_separator);

    /* --- GtkNotebook (expands horizontally) --- */
    g_notebook = gtk_notebook_new();
    gtk_notebook_set_scrollable(GTK_NOTEBOOK(g_notebook), TRUE);
    gtk_widget_set_hexpand(g_notebook, TRUE);
    gtk_widget_set_margin_end(g_notebook, 6);

    /* Add 3 tabs with content */
    const char *tab_names[] = {"Lazarus", "Compiler", "Debugger"};
    for (int i = 0; i < 3; i++) {
        GtkWidget *page_content;
        if (i == 0) {
            /* First tab: label + text view */
            GtkWidget *box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 6);
            gtk_widget_set_margin_start(box, 6);
            gtk_widget_set_margin_end(box, 6);
            gtk_widget_set_margin_top(box, 6);
            gtk_widget_set_margin_bottom(box, 6);

            GtkWidget *lbl = gtk_label_new("This is a test label simulating the Lazarus directory info");
            gtk_widget_set_halign(lbl, GTK_ALIGN_START);
            gtk_box_append(GTK_BOX(box), lbl);

            GtkWidget *sw = gtk_scrolled_window_new();
            gtk_widget_set_vexpand(sw, TRUE);
            GtkWidget *tv = gtk_text_view_new();
            GtkTextBuffer *buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv));
            gtk_text_buffer_set_text(buf, "Test memo content\nsimulating LazDirMemo", -1);
            gtk_text_view_set_editable(GTK_TEXT_VIEW(tv), FALSE);
            gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(sw), tv);
            gtk_box_append(GTK_BOX(box), sw);

            page_content = box;
        } else {
            page_content = gtk_label_new("");
        }

        GtkWidget *tab_label = gtk_label_new(tab_names[i]);
        gtk_notebook_append_page(GTK_NOTEBOOK(g_notebook), page_content, tab_label);
    }
    gtk_box_append(GTK_BOX(hbox), g_notebook);

    /* --- Button panel (bottom, fixed height) --- */
    g_btn_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_widget_set_margin_start(g_btn_box, 10);
    gtk_widget_set_margin_end(g_btn_box, 10);
    gtk_widget_set_margin_top(g_btn_box, 10);
    gtk_widget_set_margin_bottom(g_btn_box, 10);

    /* Spacer pushes button to the right */
    GtkWidget *spacer = gtk_label_new("");
    gtk_widget_set_hexpand(spacer, TRUE);
    gtk_box_append(GTK_BOX(g_btn_box), spacer);

    g_button = gtk_button_new_with_label("Start IDE");
    gtk_widget_set_size_request(g_button, 100, -1);
    gtk_box_append(GTK_BOX(g_btn_box), g_button);
    gtk_box_append(GTK_BOX(g_vbox), g_btn_box);

    /* --- Show window --- */
    gtk_window_present(GTK_WINDOW(window));

    /* Dump allocations after layout settles */
    g_timeout_add(500, dump_after_show, NULL);
}

int main(int argc, char **argv) {
    GtkApplication *app = gtk_application_new("org.test.setupdialog",
                                               G_APPLICATION_FLAGS_NONE);
    g_signal_connect(app, "activate", G_CALLBACK(on_activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}
