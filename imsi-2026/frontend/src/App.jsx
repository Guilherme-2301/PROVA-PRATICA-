import { useEffect, useState } from 'react'
import FutaComponent from './components/frutaComponent'
import './App.css'

// URL da API usada pelo NAVEGADOR (definida no build via VITE_API_URL)
const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:3000'

function App() {
  const [frutas, setFruta] = useState([])

  async function getFrutas() {
    try {
      const res = await fetch(`${API_URL}/frutas`)
      const data = await res.json()
      setFruta(data)
    } catch (error) {
      console.error("Failed to fetch frutas:", error)
    }
  }

  useEffect(() => {
    getFrutas()
  }, [])

  return (
    <div >
      <img src="" alt="" />
      teste
      {
        frutas ? frutas.map((fruta) => (<FutaComponent key={fruta.id} data={fruta} />)) : <div>...carregando</div>
      }
    </div>
  )
}

export default App