# Partes da Tarefa 4

* modificar o jogo para criar um array (tabela) de blips (em ```love.load```).
  * jogo acaba se jogador atingir todos
* atribuir a cada blip uma velocidade aleatoria (usar ```love.math.random```)
  * se blip completar `X` voltas sem ser atingido, deve mudar de desenho e se tornar "imortal"
  * se o jogo atingir Y blips imortais, o jogador perde
  * acrescentar mais métodos ao blip para implementar essas funcionalidades. Procurar deixar o mínimo de estado em variáveis globais
* procure criar novos blips aleatoriamente ao longo do jogo
* mostrar tela "ganhou" ou "perdeu"