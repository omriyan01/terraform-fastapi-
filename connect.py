from fastapi import FastAPI, HTTPException
import psycopg2

# Database connection details
DB_HOST = "20.105.194.249"
DB_PORT = "5432"
DB_NAME = "omridb"
DB_USER = "omri"
DB_PASSWORD = "Hapoe_l6984"

app = FastAPI()


try:
    connection = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )
except Exception as e:
    raise HTTPException(status_code=500, detail=f"Error connecting to the database: {e}")
    
   
cursor = connection.cursor()

@app.get("/")
async def get_clients():
    cursor.execute("""SELECT * FROM clients""")
    clients = cursor.fetchall()
    return clients

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
