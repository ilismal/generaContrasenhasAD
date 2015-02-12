<#

.AUTHOR
Ignacio Lis

.SYNOPSIS
Provisionamiento de usuarios para xxxx

.DESCRIPTION
La función Asignar-Contraseña asigna una contraseña (la misma) a cada usuario de la lista
El cuerpo del script recoge los usuarios, sus direcciones de correo y su estado de un CSV. Para los usuarios activos
y con correo genera una contraseña y la envía por correo.
Formato del csv de entrada:
=====================
email,username,estado
usuario1@dominio1.com,usu1,activo
usuario2@otrodominio.com,usu2,bloqueado
(...)
=====================

.NOTES
Ejecutar con un usuario administrador del dominio

#>

function Enviar-Correo {
  Param([string]$dirección,[string]$nombreDeUsuario,[string]$contraseña)
  $asunto = "Contraseña para el usuario " + $nombreDeUsuario + " en xxxx"
  #Modificar para indicar una dirección de origen adecuada
  $origen = "direccion@de.correo"
  #Revisar si es correcto dar este contacto
  $soporte = "soporte@dominio.com"
  #Servidor utilizado para el envío
  $servidor = "smtp.dominio.local"
  #Cuerpo del mensaje en HTML
  #Revisar redacción y URL indicada
  $cuerpo = "<p>Se le ha creado una cuenta en <a href=`"http://loquesea.com`">xxxx</a>.</p>`
  <p>Puede acceder con su usuario " + $nombreDeUsuario + " y la contraseña " + $contraseña + "</p>`
  <p>Si tiene cualquier duda póngase en contacto con " + $soporte + "</p>"
  Send-MailMessage -To $dirección -Subject $asunto -Body $cuerpo -From $origen -SmtpServer $servidor -Encoding UTF8 -BodyAsHtml
}

function Asignar-Contraseña {
  Param([string]$usuario,[string]$contraseña,[pscredential]$credenciales)
  $nuevaContraseña = ConvertTo-SecureString $contraseña -AsPlainText -Force
  #Modificar para apuntar al DC que corresponda
  Set-ADAccountPassword -Identity $usuario -NewPassword $nuevaContraseña -Credential $credenciales -Server dc.local
}

#Contraseña de mi usuario en DOMINIODESARROLLO
#Esto no se hace, pero en casa del herrero...
$contraseñadaDominioDesarrollo = ConvertTo-SecureString "contraseñasupersecreta" -AsPlainText -Force
#Credenciales para ese dominio
$credencialesDominioDesarrollo = New-Object System.Management.Automation.PSCredential("USUARIODOMINIO",$contraseñadaDominioDesarrollo)

Import-Csv -Path .\listausuarios.csv -Delimiter "," | ForEach-Object {
  #Eliminamos usuarios sin correo electrónico
  if ($_.email) {
    #Realizamos la tarea únicamente para usuarios activos
    if ($_.estado -eq "activo") {
      #Try/Catch
      Try {
        $contraseña = "lamismaparatodos"
        Asignar-Contraseña -usuario $_.username -contraseña $contraseña -credenciales $credencialesDominioDesarrollo
        Write-Host "Asignada al usuario" $_.username "con correo-e" $_.email "la contraseña:" $contraseña
        Enviar-Correo -dirección $_.email -nombreDeUsuario $_.username -contraseña $contraseña
      }
      Catch {
        $mensajeDeError = $_.Exception.Message
        Write-Host $mensajeDeError
      }
    }
  }
}
