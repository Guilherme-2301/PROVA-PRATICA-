import express from 'express'
import cors from 'cors'
import { frutasRouter } from './routes/frutas.routes.js'
import { pool } from './config/db.js'

const app = express()

app.use(cors())

app.get('/', (req, res) => {
    return res.send("Hola Mundo")
})


app.get('/health', async (req, res) => {
    try {
        await pool.query('SELECT 1')
        return res.status(200).json({ status: 'ok', database: 'up' })
    } catch (error) {
        console.error('Healthcheck falhou: nao foi possivel consultar o banco:', error.message)
        return res.status(503).json({ status: 'error', database: 'down' })
    }
})

app.use('/frutas', frutasRouter)

app.listen(3000, () => {
    console.log(`API Rodando em: http://localhost:3000`);

})