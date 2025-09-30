import sys
import logging
from PyQt6.QtWidgets import QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QListWidget, QListWidgetItem, QLabel, QMessageBox, QLineEdit, QFileDialog, QTabWidget
from PyQt6.QtCore import Qt, pyqtSignal

logger = logging.getLogger(__name__)

class SimpleModsList(QWidget):
    mod_activated = pyqtSignal(str)
    
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout(self)
        self.list_widget = QListWidget()
        self.list_widget.setSelectionMode(QListWidget.SelectionMode.SingleSelection)
        self.list_widget.itemDoubleClicked.connect(self.on_item_double_clicked)
        layout.addWidget(QLabel("Mods (Double-click):"))
        layout.addWidget(self.list_widget)
        btn_layout = QHBoxLayout()
        self.activate_btn = QPushButton("Toggle")
        self.activate_btn.clicked.connect(self.on_toggle_clicked)
        btn_layout.addWidget(self.activate_btn)
        layout.addLayout(btn_layout)
    
    def load_mods(self, mods_info):
        self.list_widget.clear()
        for mod in mods_info:
            status = '[ON]' if mod.is_active else '[OFF]'
            item = QListWidgetItem(f"{status} {mod.name}")
            item.setData(Qt.ItemDataRole.UserRole, mod.id)
            if mod.is_active:
                item.setForeground(Qt.GlobalColor.green)
            self.list_widget.addItem(item)
    
    def on_item_double_clicked(self, item):
        self.mod_activated.emit(item.data(Qt.ItemDataRole.UserRole))
    
    def on_toggle_clicked(self):
        item = self.list_widget.currentItem()
        if item:
            self.mod_activated.emit(item.data(Qt.ItemDataRole.UserRole))

class SettingsTab(QWidget):
    paths_changed = pyqtSignal(str, str)
    
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout(self)
        layout.addWidget(QLabel("SaveMods Path:"))
        ml = QHBoxLayout()
        self.mods_path_input = QLineEdit()
        self.mods_browse_btn = QPushButton("Browse")
        self.mods_browse_btn.clicked.connect(self.browse_mods_path)
        ml.addWidget(self.mods_path_input)
        ml.addWidget(self.mods_browse_btn)
        layout.addLayout(ml)
        layout.addWidget(QLabel("Mods Path:"))
        sl = QHBoxLayout()
        self.save_path_input = QLineEdit()
        self.save_browse_btn = QPushButton("Browse")
        self.save_browse_btn.clicked.connect(self.browse_save_path)
        sl.addWidget(self.save_path_input)
        sl.addWidget(self.save_browse_btn)
        layout.addLayout(sl)
        self.save_btn = QPushButton("Save")
        self.save_btn.clicked.connect(self.on_save_clicked)
        layout.addWidget(self.save_btn)
        layout.addStretch()
    
    def browse_mods_path(self):
        path = QFileDialog.getExistingDirectory(self, "Select SaveMods")
        if path:
            self.mods_path_input.setText(path)
    
    def browse_save_path(self):
        path = QFileDialog.getExistingDirectory(self, "Select Mods")
        if path:
            self.save_path_input.setText(path)
    
    def on_save_clicked(self):
        self.paths_changed.emit(self.mods_path_input.text(), self.save_path_input.text())

class MainWindow(QMainWindow):
    def __init__(self, mod_manager, config_manager):
        super().__init__()
        self.mod_manager = mod_manager
        self.config_manager = config_manager
        self.setWindowTitle("Mod Manager")
        self.setGeometry(100, 100, 800, 600)
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        self.tabs = QTabWidget()
        self.mods_tab = SimpleModsList()
        self.mods_tab.mod_activated.connect(self.on_mod_toggled)
        self.settings_tab = SettingsTab()
        self.settings_tab.paths_changed.connect(self.on_settings_saved)
        self.tabs.addTab(self.mods_tab, "Mods")
        self.tabs.addTab(self.settings_tab, "Settings")
        layout.addWidget(self.tabs)
        self.status_label = QLabel("Ready")
        layout.addWidget(self.status_label)
        self.refresh_btn = QPushButton("Refresh")
        self.refresh_btn.clicked.connect(self.refresh_mods)
        layout.addWidget(self.refresh_btn)
        self.load_settings()
    
    def load_settings(self):
        mp = self.config_manager.get_mods_path()
        sp = self.config_manager.get_save_mods_path()
        if mp:
            self.settings_tab.mods_path_input.setText(str(mp))
        if sp:
            self.settings_tab.save_path_input.setText(str(sp))
    
    def refresh_mods(self):
        try:
            self.status_label.setText("Loading...")
            mi = self.mod_manager.scan_mods_detailed()
            self.mods_tab.load_mods(mi)
            self.status_label.setText(f"Loaded {len(mi)} mods")
        except Exception as e:
            self.status_label.setText(f"Error: {e}")
    
    def on_mod_toggled(self, mod_id):
        try:
            if self.mod_manager.is_mod_active(mod_id):
                s = self.mod_manager.deactivate_mod(mod_id)
                self.status_label.setText("Off: " + mod_id if s else "Failed")
            else:
                s, m = self.mod_manager.activate_single_mod(mod_id)
                self.status_label.setText("On: " + mod_id if s else m)
            self.refresh_mods()
        except Exception as e:
            logger.error(e)
    
    def on_settings_saved(self, mp, sp):
        try:
            self.config_manager.update({"mods_path": mp, "save_mods_path": sp, "first_run": False})
            self.mod_manager.set_paths(mp, sp)
            self.status_label.setText("Saved!")
            self.refresh_mods()
        except Exception as e:
            logger.error(e)
    
    def load_initial_data(self):
        self.refresh_mods()
