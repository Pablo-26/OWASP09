# Demostración de la Vulnerabilidad de Aleatoriedad Insegura (Insecure Randomness)

## OWASP Top 10 para Contratos Inteligentes

El OWASP Top 10 para Contratos Inteligentes es una lista de los riesgos de seguridad más críticos en el desarrollo de contratos inteligentes. Sirve como una guía fundamental para desarrolladores y auditores para identificar y mitigar vulnerabilidades comunes que pueden llevar a pérdidas financieras significativas o fallos del sistema en aplicaciones blockchain. Comprender estos riesgos es crucial para construir aplicaciones descentralizadas (dApps) seguras y robustas.

## Insecure Randomness

La Aleatoriedad Insegura (a menudo categorizada como "Aleatoriedad Débil" o "Aleatoriedad Predecible") es una vulnerabilidad crítica en los contratos inteligentes donde la generación de números aleatorios no es verdaderamente impredecible. En entornos blockchain, lograr una verdadera aleatoriedad es un desafío porque todas las transacciones y cambios de estado son públicamente visibles y deterministas.

**¿Por qué es una vulnerabilidad?**
Los contratos inteligentes a menudo dependen de números aleatorios para diversas funcionalidades, como:
*   Loterías y juegos de azar
*   Acuñación de NFTs con rasgos variables
*   Selección de validadores o participantes en un protocolo descentralizado
*   Generación de IDs únicos o claves criptográficas

Si un atacante puede predecir el número "aleatorio", puede manipular el resultado de estas funcionalidades a su favor, lo que lleva a ganancias financieras, distribución injusta o interrupción del protocolo.

**Fuentes comunes de inseguridad en la aleatoriedad blockchain:**
*   **`block.timestamp`**: La marca de tiempo del bloque actual puede ser ligeramente manipulada por los mineros (por ejemplo, retrasando o adelantando un bloque dentro de un cierto rango). Un atacante también puede predecirla con una precisión razonable.
*   **`block.number`**: Aunque aparentemente aleatorio, `block.number` es secuencial y fácilmente predecible.
*   **`block.difficulty` / `block.prevrandao` (anteriormente `block.difficulty` en Ethereum PoW)**: En las cadenas de Prueba de Trabajo (PoW), se usaba `block.difficulty`, pero también era manipulable por los mineros. En Ethereum de Prueba de Participación (PoS), se usa `block.prevrandao` (baliza pre-aleatoria), que es un valor proporcionado por la cadena de balizas. Aunque más robusto que `block.timestamp`, aún puede ser conocido por los validadores antes de que se proponga un bloque, lo que permite una posible manipulación o predicción en ciertos escenarios.
*   **`msg.sender`**: La dirección del llamador es pública y determinista.
*   **`keccak256(abi.encodePacked(...))` con entradas predecibles**: Hashear entradas predecibles (como las anteriores) siempre resultará en una salida predecible. Un atacante puede ejecutar la misma función hash con las mismas entradas fuera de la cadena para determinar el número "aleatorio" antes de que se mine la transacción.

Este proyecto demuestra cómo un atacante puede explotar un contrato que utiliza `block.timestamp`, `msg.sender` y `block.prevrandao` para generar números "aleatorios".

## Componentes del Proyecto

Este proyecto consta de los siguientes componentes clave:

*   **`contracts/InsecureRandom.sol`**: El contrato inteligente vulnerable que intenta generar un número "aleatorio" para un juego simple.
*   **`contracts/InsecureRandomAttacker.sol`**: Un contrato inteligente diseñado específicamente para explotar el contrato `InsecureRandom` prediciendo sus resultados "aleatorios".
*   **`test/`**: Contiene archivos de prueba que demuestran la funcionalidad y el exploit.
    *   `InsecureRandom.test.ts`: Pruebas básicas para el contrato `InsecureRandom`, asegurando que sus funciones principales funcionan como se espera.
    *   `InsecureRandomExploit.test.ts`: Una prueba programática que demuestra la capacidad del contrato atacante para obtener ganancias de la vulnerabilidad.
    *   `InsecureRandomExploitVisual.test.ts`: Proporciona una demostración visual, paso a paso, del exploit con registros detallados en la consola, mostrando los resultados predichos versus los reales y los cambios de saldo.

## Detalles de los Contratos

### `InsecureRandom.sol` (El Contrato Víctima)

Este contrato simula un juego simple donde los jugadores pueden apostar 0.01 ETH para ganar 0.02 ETH si un número "aleatorio" es par.

#### Funciones:

*   `constructor()`: Inicializa el contrato, estableciendo al desplegador como el propietario (`owner`).
*   `getInsecureRandomNumber() public returns (uint256)`:
    *   **Propósito**: Intenta generar un número aleatorio entre 0 y 99.
    *   **Vulnerabilidad**: Utiliza `keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao))` para generar aleatoriedad. Estos valores (`block.timestamp`, `block.prevrandao`, `msg.sender`) son públicamente conocidos y pueden ser influenciados o predichos por mineros u otros atacantes.
    *   `lastRandom` y `lastBlock` se actualizan con el número aleatorio generado y el número de bloque actual para observación.
*   `play() public payable returns (string memory)`:
    *   **Propósito**: Permite a un jugador participar en el juego.
    *   **Lógica**: Requiere un pago de 0.01 ETH. Llama internamente a `getInsecureRandomNumber()`. Si el número generado es par, el jugador gana 0.02 ETH y recibe el pago. De lo contrario, pierde su apuesta.
    *   **Vulnerabilidad**: El resultado de esta función puede ser predicho por un atacante debido a la generación de números aleatorios insegura, lo que les permite jugar solo cuando una victoria está garantizada.
*   `getBalance() public view returns (uint256)`: Devuelve el saldo actual de Ether del contrato.
*   `withdraw() public`: Permite que solo el propietario del contrato retire todo el saldo del contrato.
*   `receive() external payable`: Una función especial que permite al contrato recibir Ether sin una llamada de función específica.

### `InsecureRandomAttacker.sol` (El Contrato Atacante)

Este contrato está diseñado para explotar el contrato `InsecureRandom` prediciendo el resultado de su función `play()`.

#### Funciones:

*   `constructor(address _target)`: Inicializa el contrato atacante, estableciendo la dirección del contrato `InsecureRandom` objetivo y al desplegador como el propietario.
*   `attack() external`:
    *   **Propósito**: Ejecuta un intento de ataque sobre el contrato `InsecureRandom` objetivo.
    *   **Lógica**:
        1.  Primero, calcula un número aleatorio `predicted` utilizando la *misma fórmula exacta* que `getInsecureRandomNumber()` de `InsecureRandom.sol`. La clave aquí es que `block.timestamp`, `address(this)` (que será `msg.sender` cuando el contrato atacante llame a `play` en la víctima) y `block.prevrandao` son conocidos por el contrato atacante *antes* de que llame a la función `play` de la víctima.
        2.  Luego, verifica si el número `predicted` es par. Si lo es, esto significa que el atacante ganaría el juego.
        3.  Solo si el número `predicted` es par, llama a la función `target.play()`, enviando 0.01 ETH.
        4.  Si el número `predicted` es impar, *no* llama a `target.play()`, evitando así una pérdida garantizada.
    *   **Explotación**: Al jugar solo cuando una victoria está garantizada (o es altamente probable debido a la previsibilidad del número "aleatorio"), el atacante puede obtener ganancias consistentemente del contrato `InsecureRandom`.
*   `withdraw() external`: Permite que solo el propietario del contrato atacante retire su saldo de Ether acumulado.
*   `receive() external payable`: Habilita al contrato atacante para recibir Ether.

## Cómo Ejecutar en Remix IDE (Paso a Paso)

Este proyecto está diseñado para ser fácilmente probado y demostrado en Remix IDE.

1.  **Abrir Remix IDE**: Ve a [https://remix.ethereum.org/](https://remix.ethereum.org/).

      <img width="1915" height="962" alt="image" src="https://github.com/user-attachments/assets/7b2db86c-5e50-481a-be43-f101c13f0d2e" />

3.  **Crear Nuevos Archivos**:
    *   Navega a la pestaña "File Explorers" (normalmente el primer icono en la barra lateral izquierda).
    *   Haz clic en el icono "Create New File".
    *   Crea un nuevo archivo llamado `InsecureRandom.sol` y pega el contenido de `contracts/InsecureRandom.sol` en él.
    *   Crea otro nuevo archivo llamado `InsecureRandomAttacker.sol` y pega el contenido de `contracts/InsecureRandomAttacker.sol` en él.

        <img width="324" height="304" alt="image" src="https://github.com/user-attachments/assets/1aa4dd18-90e6-4006-83ea-47bb42821c58" />

4.  **Compilar Contratos**:
    *   Navega a la pestaña "Solidity Compiler" (normalmente el segundo icono en la barra lateral izquierda).
    *   Asegúrate de que la versión del compilador esté configurada en `0.8.18` (o una versión compatible como `0.8.x`).
    *   Haz clic en el botón "Compile InsecureRandom.sol".

         <img width="234" height="548" alt="image" src="https://github.com/user-attachments/assets/a5c35755-5d8f-4bc3-94dd-b96101b971aa" />

    *   Haz clic en el botón "Compile InsecureRandomAttacker.sol".
    *   Verifica que ambos contratos se compilen sin errores ni advertencias.


          <img width="601" height="150" alt="image" src="https://github.com/user-attachments/assets/99f5334b-2061-4223-b8ae-739268c39a18" />

3.  **Desplegar `InsecureRandom.sol` (La Víctima)**:
    *   Navega a la pestaña "Deploy & Run Transactions" (normalmente el tercer icono en la barra lateral izquierda).
    *   En el menú desplegable "ENVIRONMENT", selecciona "JavaScript VM London" (o cualquier entorno de prueba adecuado como "Remix VM (London)").
    *   En el menú desplegable "CONTRACT", selecciona `InsecureRandom`.
    *   Haz clic en el botón naranja "Deploy".
    *   Una vez desplegado, expande el contrato `InsecureRandom` bajo "Deployed Contracts".
    *   **Copia la dirección del contrato `InsecureRandom` desplegado.** Necesitarás esta dirección para el contrato atacante.

         <img width="221" height="567" alt="image" src="https://github.com/user-attachments/assets/4dbecba4-53e4-40c7-b490-406051a047d8" />

4.  **Fondear `InsecureRandom.sol` (Opcional pero Recomendado)**:
    *   Para que el juego sea realista y el contrato víctima pueda pagar las ganancias, envíale algo de Ether.
    *   En el menú desplegable "Account" en la parte superior de la pestaña "Deploy & Run Transactions", selecciona una cuenta con algo de Ether (las cuentas de Remix VM vienen pre-fondeadas).
    *   En el campo "Value", ingresa `1` y selecciona `Ether` del menú desplegable.
    *   Desplázate hacia abajo hasta el contrato `InsecureRandom` desplegado, y en la sección "Transact", puedes llamar a una función pagadera (como `play` con 0.01 Ether) o simplemente enviar Ether directamente a su dirección. Dado que `InsecureRandom.sol` tiene una función `receive()`, puedes enviar Ether directamente.
    *   Haz clic en el botón "Transact" junto al campo `Value` para enviar 1 Ether al contrato `InsecureRandom`.
5.  **Desplegar `InsecureRandomAttacker.sol` (El Atacante)**:
    *   En el menú desplegable "CONTRACT", selecciona `InsecureRandomAttacker`.
    *   Junto al botón "Deploy", verás un campo de entrada etiquetado `_target` (address). Pega la dirección copiada del contrato `InsecureRandom` desplegado en este campo.
    *   Haz clic en el botón naranja "Deploy".
    *   Una vez desplegado, expande el contrato `InsecureRandomAttacker` bajo "Deployed Contracts".
    *   **Copia la dirección del contrato `InsecureRandomAttacker` desplegado.**

         <img width="243" height="174" alt="image" src="https://github.com/user-attachments/assets/a789db6d-2a51-4794-a591-ee48bc98e9ed" />

6.  **Fondear `InsecureRandomAttacker.sol`**:
    *   El contrato atacante necesita Ether para pagar la tarifa de entrada de 0.01 ETH cuando llama a `play()` en el contrato víctima.
    *   En el menú desplegable "Account", selecciona una cuenta *diferente* a la utilizada para el propietario de `InsecureRandom` (para simular un atacante separado).
    *   En el campo "Value", ingresa `0.1` y selecciona `Ether` del menú desplegable.
    *   Envía este Ether a la dirección del contrato `InsecureRandomAttacker` desplegado. Puedes hacerlo pegando la dirección del contrato atacante en el campo "To" (si está disponible) o interactuando con una función pagadera en el contrato atacante (tiene una función `receive()`).
    *   Haz clic en el botón "Transact" junto al campo `Value` para enviar 0.1 Ether al contrato `InsecureRandomAttacker`.

        <img width="246" height="170" alt="image" src="https://github.com/user-attachments/assets/faddd095-368d-4a58-8749-c7970025494f" />
   
7.  **Ejecutar el Ataque**:
    *   Bajo el contrato `InsecureRandomAttacker` desplegado, localiza el botón `attack`.
    *   Haz clic en el botón `attack` varias veces (por ejemplo, 5-10 veces).

         <img width="244" height="181" alt="image" src="https://github.com/user-attachments/assets/08ffa9ae-5bba-4feb-85db-908a597a8bad" />

    *   **Observa los registros de transacciones en la consola de Remix (en la parte inferior).**
        *   Verás eventos `Predicted` emitidos por el contrato atacante, mostrando el número aleatorio predicho, el número de bloque y la marca de tiempo.
        *   Crucialmente, *solo* verás eventos `Played` emitidos por el contrato `InsecureRandom` (víctima) cuando la predicción del atacante fue un número par (una condición de victoria).
    *   Después de varios ataques, verifica el saldo del contrato `InsecureRandomAttacker` y del contrato `InsecureRandom` utilizando sus respectivas funciones `getBalance()`. Deberías observar que el saldo del contrato atacante aumenta (y el de la víctima disminuye) con el tiempo, demostrando la explotación exitosa.

        <img width="648" height="130" alt="image" src="https://github.com/user-attachments/assets/888e489d-1382-4bc5-b162-262c3e62a46f" />
   
7.  **Retirar las Ganancias del Atacante**:
    *   Bajo el contrato `InsecureRandomAttacker` desplegado, haz clic en el botón `withdraw`. Esto transferirá todo el Ether acumulado del contrato atacante a la EOA del atacante (la cuenta que desplegó el contrato atacante).
    *   Verifica el saldo de la EOA del atacante para confirmar las ganancias.

         <img width="239" height="130" alt="image" src="https://github.com/user-attachments/assets/95dbc97a-a1a3-4f1d-bd3b-397e839f96ad" />

