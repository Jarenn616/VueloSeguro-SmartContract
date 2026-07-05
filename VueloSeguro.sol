// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VueloSeguro {
    address public oraculoSimulado;
    uint public precioPoliza = 1 ether;
    uint public compensacion = 2 ether; 

    // 1. STRUCT: Define la estructura exacta de los datos
    struct Poliza {
        address pasajero;
        uint montoPagado;
        bool cobrada; 
    }

    // Diccionario que asocia el codigo de vuelo con los datos completos de la poliza
    mapping(string => Poliza) public polizasPorVuelo;

    // 2. EVENTOS: Dejan un registro inmutable en la blockchain
    event SeguroComprado(string vuelo, address pasajero);
    event CompensacionPagada(string vuelo, address pasajero, uint monto);

    // 3. MODIFIER: Filtro de seguridad profesional
    modifier soloOraculo() {
        require(msg.sender == oraculoSimulado, "Acceso denegado: Solo el Oraculo puede ejecutar esto");
        _;
    }

    // El payable permite que el dueño le inyecte fondos al crear el contrato
    constructor() payable {
        oraculoSimulado = msg.sender;
    }

    // FUNCIÓN 1: Comprar
    function comprarSeguro(string memory _codigoVuelo) public payable {
        require(msg.value == precioPoliza, "Debes pagar exactamente 1 ETH");
        require(polizasPorVuelo[_codigoVuelo].pasajero == address(0), "Este vuelo ya esta asegurado");

        // Guardamos los datos en la estructura
        polizasPorVuelo[_codigoVuelo] = Poliza({
            pasajero: msg.sender,
            montoPagado: msg.value,
            cobrada: false
        });

        // Emitimos el evento para la interfaz gráfica
        emit SeguroComprado(_codigoVuelo, msg.sender);
    }

    // FUNCIÓN 2: Reportar y Pagar 
    function reportarRetraso(string memory _codigoVuelo) public soloOraculo {
        // Cargamos la póliza desde la memoria
        Poliza storage poliza = polizasPorVuelo[_codigoVuelo];
        
        // Verificaciones de seguridad (Términos y condiciones)
        require(poliza.pasajero != address(0), "No existe poliza para este vuelo");
        require(!poliza.cobrada, "La compensacion ya fue pagada");
        require(address(this).balance >= compensacion, "El contrato no tiene fondos suficientes");

        // Cambiamos el estado ANTES de pagar (Buena practica de seguridad contra hackeos)
        poliza.cobrada = true; 

        // Transferencia segura
        (bool exito, ) = poliza.pasajero.call{value: compensacion}("");
        require(exito, "Fallo al transferir la compensacion");

        // Emitimos el evento de pago
        emit CompensacionPagada(_codigoVuelo, poliza.pasajero, compensacion);
    }
}