def setup_global_env():
    pass

def start_system():
    setup_global_env()
    
    from subproject_1_name.src.app.main import main_function as subproject_1_name_main_function
  
    subproject_1_name_main_function()

if __name__ == "__main__":
    start_system()
