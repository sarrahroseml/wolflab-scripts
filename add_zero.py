import pandas as pd

df = pd.read_csv('Corrected_Final_Config.csv')  

#add leading zeros
def add_leading_zero(lib_name):
    letter = lib_name[0]  #extract letter
    number = lib_name[1:]  #extract number
    formatted_number = f"{int(number):02}"  #format with leading zero
    return f"{letter}{formatted_number}"

#apply function to libary name
df['Libary Name'] = df['Libary Name'].apply(add_leading_zero)

df.to_csv('Format_Config.csv', index=False) 
