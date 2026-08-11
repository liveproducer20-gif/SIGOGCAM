import pyodbc
conn = pyodbc.connect('DRIVER={ODBC Driver 18 for SQL Server};SERVER=database;DATABASE=BITSAC;UID=sa;PWD=SigoDb!7Qm2L9v4X8p6R3k;TrustServerCertificate=yes')
cur = conn.cursor()
cur.execute("SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('dbo.lugares_servicio')")
cols = [r[0] for r in cur.fetchall()]
print('ALL COLUMNS:', cols)
print('Has lugar_formacion:', 'lugar_formacion' in cols)
conn.close()
