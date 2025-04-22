CREATE OR REPLACE FUNCTION limpiar_fallos()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.exito = TRUE THEN
        DELETE FROM intentos_login
        WHERE id_usuario = NEW.id_usuario AND exito = FALSE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_limpia_fallos
AFTER INSERT ON intentos_login
FOR EACH ROW
EXECUTE FUNCTION limpiar_fallos();

CREATE OR REPLACE FUNCTION public.limitar_historial_contrasenas()
 RETURNS trigger                                                 
 LANGUAGE plpgsql                                                
AS $function$                                                    
BEGIN                                                            
    DELETE FROM Historial_contrasenas                            
    WHERE id_usuario = NEW.id_usuario                            
    AND id_historial NOT IN (                                    
        SELECT id_historial FROM Historial_contrasenas           
        WHERE id_usuario = NEW.id_usuario                        
        ORDER BY fecha_registro DESC                             
        LIMIT 5                                                  
    );                                                           
    RETURN NEW;                                                  
END;                                                             
$function$   
